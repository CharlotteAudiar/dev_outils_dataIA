# v1 — installée dans Open WebUI le 27/08/2026 (Merlin)
"""
title: Explorateur Postgres (sandbox Audiar)
author: Charlotte
version: 0.1.0
description: >
    Tool Open WebUI natif (sans MCP/mcpo) pour explorer une base Postgres avec les identifiants
    personnels de chaque utilisateur. Les droits d'écriture sont déjà contrôlés côté Postgres
    (chaque compte n'a d'écriture que sur son propre schéma sandbox) : ce Tool ne fait
    volontairement aucun filtrage de requête supplémentaire.
requirements: psycopg2-binary
"""

from pydantic import BaseModel, Field
import asyncio
import psycopg2
import psycopg2.extras


class Tools:
    class UserValves(BaseModel):
        pg_host: str = Field(default="perceval2.audiar.net", description="Hôte Postgres")
        pg_port: int = Field(default=5432, description="Port Postgres")
        pg_database: str = Field(default="sandbox", description="Base de données")
        pg_user: str = Field(default="", description="Identifiant Postgres personnel")
        pg_password: str = Field(
            default="",
            description="Mot de passe Postgres personnel",
            json_schema_extra={"input": {"type": "password"}},
        )

    def __init__(self):
        self.citation = True

    def _connect(self, uv: "Tools.UserValves"):
        return psycopg2.connect(
            host=uv.pg_host,
            port=uv.pg_port,
            dbname=uv.pg_database,
            user=uv.pg_user,
            password=uv.pg_password,
            connect_timeout=5,
        )

    def _check_valves(self, __user__: dict):
        uv = (__user__ or {}).get("valves")
        if not uv or not uv.pg_user:
            return None, (
                "Identifiants Postgres non configurés. Renseigne-les dans "
                "Réglages personnels > Outils > Explorateur Postgres."
            )
        return uv, None

    # --- Logique synchrone (psycopg2 est une bibliothèque bloquante) -------------------------
    # Isolée dans des méthodes privées, exécutées dans un thread séparé via asyncio.to_thread
    # depuis les méthodes publiques async ci-dessous, pour ne pas bloquer la boucle asyncio
    # d'Open WebUI pendant l'accès réseau à Postgres.

    def _list_tables_sync(self, uv: "Tools.UserValves") -> str:
        with self._connect(uv) as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT table_name FROM information_schema.tables "
                    "WHERE table_schema = 'public' ORDER BY table_name;"
                )
                rows = [r[0] for r in cur.fetchall()]
        return "\n".join(rows) if rows else "Aucune table trouvée dans le schéma public."

    def _describe_table_sync(self, table_name: str, uv: "Tools.UserValves") -> str:
        with self._connect(uv) as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT column_name, data_type, is_nullable "
                    "FROM information_schema.columns "
                    "WHERE table_schema = 'public' AND table_name = %s "
                    "ORDER BY ordinal_position;",
                    (table_name,),
                )
                rows = cur.fetchall()
        if not rows:
            return f"Table '{table_name}' introuvable ou sans colonnes visibles."
        lines = [f"{c} | {t} | nullable={n}" for c, t, n in rows]
        return "\n".join(lines)

    def _execute_query_sync(self, sql: str, uv: "Tools.UserValves") -> str:
        with self._connect(uv) as conn:
            with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
                cur.execute(sql)
                if cur.description is None:
                    conn.commit()
                    return f"Requête exécutée ({cur.rowcount} ligne(s) affectée(s))."
                rows = cur.fetchmany(200)
        if not rows:
            return "Aucun résultat."
        headers = list(rows[0].keys())
        lines = [" | ".join(headers)]
        for r in rows:
            lines.append(" | ".join(str(r[h]) for h in headers))
        return "\n".join(lines)

    # --- Outils exposés au modèle (async, conformément à la recommandation Open WebUI) -------

    async def list_tables(self, __user__: dict) -> str:
        """
        Liste les tables accessibles dans le schéma public de la base Postgres.
        """
        uv, err = self._check_valves(__user__)
        if err:
            return err
        try:
            return await asyncio.to_thread(self._list_tables_sync, uv)
        except Exception as e:
            return f"Erreur de connexion ou de requête : {e}"

    async def describe_table(self, table_name: str, __user__: dict) -> str:
        """
        Décrit les colonnes d'une table donnée (nom, type, nullable).
        :param table_name: Nom de la table à décrire.
        """
        uv, err = self._check_valves(__user__)
        if err:
            return err
        try:
            return await asyncio.to_thread(self._describe_table_sync, table_name, uv)
        except Exception as e:
            return f"Erreur de connexion ou de requête : {e}"

    async def execute_query(self, sql: str, __user__: dict) -> str:
        """
        Exécute une requête SQL sur la base Postgres et retourne les résultats (200 lignes max).
        Les droits réels (lecture/écriture) sont ceux du compte Postgres personnel de
        l'utilisateur — ce Tool n'ajoute aucune restriction supplémentaire.
        :param sql: Requête SQL à exécuter.
        """
        uv, err = self._check_valves(__user__)
        if err:
            return err
        try:
            return await asyncio.to_thread(self._execute_query_sync, sql, uv)
        except Exception as e:
            return f"Erreur de connexion ou de requête : {e}"
