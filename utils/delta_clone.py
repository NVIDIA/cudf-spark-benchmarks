# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
"""Run-scoped managed shallow clones for immutable Delta benchmark inputs."""

import logging
import uuid


logger = logging.getLogger(__name__)


def new_run_session(spark_session, spark_properties):
    """Isolate a clone run, inheriting runtime settings before property overrides.

    newSession does not inherit runtime overrides applied by getOrCreate to an
    existing session. Copy the caller's settings, including custom RAPIDS keys,
    then apply the property file. Warn about immutable settings instead of
    trying to reset startup values that Spark may have normalized.
    """
    # Inspect already-loaded classes so classic Spark never imports optional
    # Connect dependencies. Include base classes to recognize Connect subclasses.
    if any(cls.__module__ == 'pyspark.sql.connect.session'
           for cls in type(spark_session).__mro__):
        raise ValueError(
            "Delta shallow-clone runs require a classic Spark session: "
            "Spark Connect does not support newSession() isolation. "
            "Use spark-submit without --spark_connect or SPARK_REMOTE.")

    # PySpark's RuntimeConfig.getAll is only available starting in Spark 4.0.
    settings = {}
    entries = spark_session._jsparkSession.conf().getAll().iterator()
    while entries.hasNext():
        entry = entries.next()
        settings[entry._1()] = entry._2()
    settings.update(spark_properties)

    run_session = spark_session.newSession()
    config_entry = spark_session._jvm.org.apache.spark.internal.config.ConfigEntry
    for key, value in settings.items():
        if run_session.conf.get(key, None) != value:
            # isModifiable also returns false for unregistered custom settings,
            # although RuntimeConfig.set accepts them (including RAPIDS keys).
            if run_session.conf.isModifiable(key) or config_entry.findEntry(key) is None:
                run_session.conf.set(key, value)
            else:
                logger.warning('Ignoring non-modifiable Spark setting %s for the Delta run; '
                               'keeping the existing application value', key)
    return run_session


def _quote_identifier(identifier):
    return "`{}`".format(identifier.replace("`", "``"))


class DeltaCloneScope:
    """Own a unique database of managed shallow clones in a run-owned SQL session."""

    def __init__(self, spark_session, database_prefix):
        self._spark_session = spark_session
        self.previous_database = spark_session.catalog.currentDatabase()
        self.database_name = "{}_{}".format(database_prefix, uuid.uuid4().hex)
        self._database_identifier = _quote_identifier(self.database_name)
        self._is_open = False

        create_database_sql = "CREATE DATABASE {}".format(self._database_identifier)
        print(create_database_sql)
        spark_session.sql(create_database_sql)
        self._is_open = True
        try:
            spark_session.catalog.setCurrentDatabase(self.database_name)
        except Exception:
            self.close()
            raise

    def clone_table(self, source_path, table_name):
        """Create a managed shallow clone whose unqualified name resolves in this scope."""
        # Delta SQL recognizes path-based identifiers only when the path is absolute.
        # Use Hadoop's working directory and default filesystem, as Spark's readers do.
        path = self._spark_session._jvm.org.apache.hadoop.fs.Path(source_path)
        if not path.isAbsolute():
            hadoop_conf = self._spark_session._jsparkSession.sessionState().newHadoopConf()
            source_path = path.getFileSystem(hadoop_conf).makeQualified(path).toString()
        table_identifier = "{}.{}".format(
            self._database_identifier, _quote_identifier(table_name))
        source_identifier = "delta.{}".format(_quote_identifier(source_path))
        clone_sql = "CREATE TABLE {} SHALLOW CLONE {}".format(
            table_identifier, source_identifier)
        print(clone_sql)
        self._spark_session.sql(clone_sql)

    def close(self):
        """Attempt cleanup without hiding run errors or preventing result output."""
        if not self._is_open:
            return
        try:
            self._spark_session.catalog.setCurrentDatabase(self.previous_database)
        except Exception:
            logger.warning('Failed to restore database %s after the Delta run',
                           self.previous_database, exc_info=True)
        drop_database_sql = "DROP DATABASE {} CASCADE".format(self._database_identifier)
        print(drop_database_sql)
        try:
            self._spark_session.sql(drop_database_sql)
        except Exception:
            logger.warning('Failed to drop Delta clone database %s; manual cleanup may be needed',
                           self.database_name, exc_info=True)
        else:
            self._is_open = False

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.close()
