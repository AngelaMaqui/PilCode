import os
import subprocess
from flask import Blueprint, flash, redirect, url_for, render_template
from utils.decorators import role_required

backups_bp = Blueprint('backups', __name__)
BACKUP_DIR = os.path.join(os.getcwd(), 'backups')

@backups_bp.route('/admin/backups')
@role_required([1])
def listar_backups():
    if not os.path.exists(BACKUP_DIR):
        os.makedirs(BACKUP_DIR)
    archivos = [f for f in os.listdir(BACKUP_DIR) if f.endswith('.sql')]
    return render_template('admin/backups.html', backups=archivos)


@backups_bp.route('/admin/backups/crear', methods=['POST'])
@role_required([1])
def crear_backup():
    """Genera volcados estructurales automáticos (.sql) invocando mysqldump"""
    if not os.path.exists(BACKUP_DIR):
        os.makedirs(BACKUP_DIR)
        
    import datetime
    fecha = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    nombre_archivo = f"respaldo_pil_{fecha}.sql"
    ruta_sql = os.path.join(BACKUP_DIR, nombre_archivo)
    comando = f"mysqldump -u root pil_andina_db > {ruta_sql}"
    
    try:
        subprocess.run(comando, shell=True, check=True)
        flash(f"Copia de seguridad '{nombre_archivo}' creada con éxito.", "success")
    except subprocess.CalledProcessError as e:
        flash(f"Error crítico en el subsistema de respaldos: {str(e)}", "danger")
        
    return redirect(url_for('backups.listar_backups'))