from flask import Blueprint, render_template
from database import get_db_connection
from utils.decorators import role_required

monitoreo_bp = Blueprint('monitoreo', __name__)

@monitoreo_bp.route('/admin/monitoreo')
@role_required([1])
def panel_control():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SHOW STATUS LIKE 'Threads_connected'")
    conexiones = cursor.fetchone()
    cursor.execute("SELECT * FROM logs_auditoria ORDER BY fecha_accion DESC LIMIT 50")
    logs = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('admin/monitoreo.html', conexiones=conexiones['Value'] if conexiones else 1, logs=logs)