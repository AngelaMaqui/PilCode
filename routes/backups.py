import os
import subprocess
from flask import Blueprint, flash, redirect, url_for, render_template, request
from database import db_config
from utils.decorators import role_required

backups_bp = Blueprint('backups', __name__)
BACKUP_DIR = os.path.join(os.getcwd(), 'backups')


@backups_bp.route('/admin/backups')
@role_required([1])
def listar_backups():
    if not os.path.exists(BACKUP_DIR):
        os.makedirs(BACKUP_DIR)
    archivos = sorted(
        [f for f in os.listdir(BACKUP_DIR) if f.endswith('.sql')],
        reverse=True
    )
    return render_template('admin/backups.html', backups=archivos)


@backups_bp.route('/admin/backups/crear', methods=['POST'])
@role_required([1])
def crear_backup():
    if not os.path.exists(BACKUP_DIR):
        os.makedirs(BACKUP_DIR)

    import datetime
    fecha = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
    nombre_archivo = f'respaldo_pil_{fecha}.sql'
    ruta_sql = os.path.join(BACKUP_DIR, nombre_archivo)
    db = db_config['database']
    user = db_config['user']
    pwd = db_config.get('password', '')
    port = db_config.get('port', 3306)
    auth = f'-p{pwd}' if pwd else ''
    comando = f'mysqldump -u {user} {auth} -P {port} {db} > "{ruta_sql}"'

    try:
        subprocess.run(comando, shell=True, check=True)
        flash(f"Copia de seguridad '{nombre_archivo}' creada con éxito.", 'success')
    except subprocess.CalledProcessError as e:
        flash(f'Error al crear respaldo: {e}', 'danger')

    return redirect(url_for('backups.listar_backups'))


@backups_bp.route('/admin/backups/restaurar', methods=['POST'])
@role_required([1])
def restaurar_backup():
    archivo = request.form.get('archivo', '')
    ruta = os.path.join(BACKUP_DIR, archivo)

    if not archivo or not archivo.endswith('.sql') or not os.path.isfile(ruta):
        flash('Archivo de respaldo no válido.', 'danger')
        return redirect(url_for('backups.listar_backups'))

    db = db_config['database']
    user = db_config['user']
    pwd = db_config.get('password', '')
    port = db_config.get('port', 3306)
    auth = f'-p{pwd}' if pwd else ''
    comando = f'mysql -u {user} {auth} -P {port} {db} < "{ruta}"'

    try:
        subprocess.run(comando, shell=True, check=True)
        flash(f"Base de datos restaurada desde '{archivo}'.", 'success')
    except subprocess.CalledProcessError as e:
        flash(f'Error al restaurar: {e}', 'danger')

    return redirect(url_for('backups.listar_backups'))
