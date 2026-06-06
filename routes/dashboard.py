from flask import Blueprint, render_template
from database import get_db_connection
from utils.decorators import role_required

dashboard_bp = Blueprint('dashboard', __name__)


@dashboard_bp.route('/dashboard')
@role_required([1, 2, 3])
def index():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute('SELECT COUNT(*) AS total FROM productos')
    total_productos = cursor.fetchone()['total']

    cursor.execute("SELECT COUNT(*) AS total FROM vista_alertas_vencimiento")
    alertas_venc = cursor.fetchone()['total']

    cursor.execute("SELECT COUNT(*) AS total FROM pedidos WHERE estado_pedido = 'Pendiente'")
    pedidos_pend = cursor.fetchone()['total']

    cursor.execute("SELECT COUNT(*) AS total FROM distribuidores")
    total_dist = cursor.fetchone()['total']

    cursor.execute(
        '''SELECT p.nombre_planta AS planta, COALESCE(SUM(l.cantidad_producida), 0) AS produccion
           FROM plantas p
           LEFT JOIN lotes l ON l.id_planta_origen = p.id_planta
               AND MONTH(l.fecha_produccion) = MONTH(CURDATE())
               AND YEAR(l.fecha_produccion) = YEAR(CURDATE())
           GROUP BY p.id_planta, p.nombre_planta
           ORDER BY p.id_planta'''
    )
    produccion_planta = cursor.fetchall()

    cursor.execute(
        '''SELECT Estado_Inventario AS estado, COUNT(*) AS cantidad
           FROM vista_stock_consolidado
           GROUP BY Estado_Inventario'''
    )
    estados_stock = cursor.fetchall()

    cursor.execute('SELECT * FROM vista_pedidos_pendientes LIMIT 5')
    pedidos_recientes = cursor.fetchall()

    cursor.execute('SELECT * FROM vista_alertas_vencimiento ORDER BY Dias_Restantes ASC LIMIT 5')
    vencimientos = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template(
        'dashboard.html',
        total_productos=total_productos,
        alertas_venc=alertas_venc,
        pedidos_pend=pedidos_pend,
        total_dist=total_dist,
        produccion_planta=produccion_planta,
        estados_stock=estados_stock,
        pedidos_recientes=pedidos_recientes,
        vencimientos=vencimientos,
    )
