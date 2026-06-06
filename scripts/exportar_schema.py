"""Genera sql/pil_andina_schema.sql desde la BD activa."""
import os
import sys
import mysql.connector

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from database import db_config

OUT = os.path.join(os.path.dirname(__file__), '..', 'sql', 'pil_andina_schema.sql')

conn = mysql.connector.connect(**db_config)
cur = conn.cursor()

lines = [
    '-- PIL Andina - Esquema de base de datos',
    '-- Generado automáticamente desde la BD activa',
    f"CREATE DATABASE IF NOT EXISTS `{db_config['database']}`;",
    f"USE `{db_config['database']}`;",
    '',
]

cur.execute('SHOW FULL TABLES WHERE Table_type = "BASE TABLE"')
tables = [r[0] for r in cur.fetchall()]
for table in tables:
    cur.execute(f'SHOW CREATE TABLE `{table}`')
    lines.append(f'DROP TABLE IF EXISTS `{table}`;')
    lines.append(cur.fetchone()[1] + ';')
    lines.append('')

cur.execute("SHOW FULL TABLES WHERE Table_type = 'VIEW'")
views = [r[0] for r in cur.fetchall()]
for view in views:
    cur.execute(f'SHOW CREATE VIEW `{view}`')
    lines.append(f'DROP VIEW IF EXISTS `{view}`;')
    lines.append(cur.fetchone()[1] + ';')
    lines.append('')

cur.execute("SHOW PROCEDURE STATUS WHERE Db=%s", (db_config['database'],))
procs = [r[1] for r in cur.fetchall()]
for proc in procs:
    cur.execute(f'SHOW CREATE PROCEDURE `{proc}`')
    lines.append(f'DROP PROCEDURE IF EXISTS `{proc}`;')
    lines.append('DELIMITER ;;')
    lines.append(cur.fetchone()[2] + ';;')
    lines.append('DELIMITER ;')
    lines.append('')

cur.execute('SHOW TRIGGERS')
triggers = {}
for row in cur.fetchall():
    triggers[row[0]] = row[2]
for name, table in triggers.items():
    cur.execute(f'SHOW CREATE TRIGGER `{name}`')
    lines.append(f'DROP TRIGGER IF EXISTS `{name}`;')
    lines.append('DELIMITER ;;')
    lines.append(cur.fetchone()[2] + ';;')
    lines.append('DELIMITER ;')
    lines.append('')

cur.close()
conn.close()

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))

print(f'Exportado: {OUT}')
