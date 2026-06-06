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

    cursor.execute("SHOW STATUS LIKE 'Slow_queries'")
    slow_queries = cursor.fetchone()

    cursor.execute("SHOW STATUS LIKE 'Uptime'")
    uptime = cursor.fetchone()

    cursor.execute('SELECT COUNT(*) AS total FROM logs_auditoria')
    total_logs = cursor.fetchone()['total']

    cursor.execute('SELECT * FROM logs_auditoria ORDER BY fecha_accion DESC LIMIT 50')
    logs = cursor.fetchall()

    cursor.execute('SHOW PROCESSLIST')
    procesos = cursor.fetchall()

    cursor.execute(
        '''EXPLAIN SELECT * FROM vista_stock_consolidado WHERE Producto LIKE %s''',
        ('%Pace%',)
    )
    explain_stock = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template(
        'admin/monitoreo.html',
        conexiones=conexiones['Value'] if conexiones else '0',
        slow_queries=slow_queries['Value'] if slow_queries else '0',
        uptime=uptime['Value'] if uptime else '0',
        total_logs=total_logs,
        logs=logs,
        procesos=procesos,
        explain_stock=explain_stock,
    )
