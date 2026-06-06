from flask import Blueprint, render_template, request
from database import get_db_connection
from utils.decorators import role_required
from utils.helpers import csv_response

reportes_bp = Blueprint('reportes', __name__)


@reportes_bp.route('/reportes')
@role_required([1, 2])
def index():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute('SELECT * FROM vista_stock_consolidado ORDER BY Producto, Planta')
    stock = cursor.fetchall()

    cursor.execute('SELECT * FROM vista_alertas_vencimiento ORDER BY Dias_Restantes')
    vencimientos = cursor.fetchall()

    cursor.execute('SELECT * FROM vista_pedidos_pendientes')
    pedidos_pend = cursor.fetchall()

    cursor.execute(
        '''SELECT pr.nombre_comercial AS producto, pre.volumen AS presentacion,
                  COALESCE(SUM(CASE WHEN MONTH(m.fecha_movimiento)=MONTH(CURDATE()) AND m.tipo_movimiento='Salida' THEN m.cantidad ELSE 0 END),0) AS salidas_mes_actual,
                  COALESCE(SUM(CASE WHEN MONTH(m.fecha_movimiento)=MONTH(DATE_SUB(CURDATE(),INTERVAL 1 MONTH)) AND m.tipo_movimiento='Salida' THEN m.cantidad ELSE 0 END),0) AS salidas_mes_anterior
           FROM productos pr
           JOIN presentaciones pre ON pr.id_producto = pre.id_producto
           LEFT JOIN movimientos_inventario m ON m.id_presentacion = pre.id_presentacion
           GROUP BY pr.id_producto, pre.id_presentacion, pr.nombre_comercial, pre.volumen
           ORDER BY pr.nombre_comercial'''
    )
    rotacion = cursor.fetchall()

    cursor.execute(
        '''SELECT p.nombre_planta, COUNT(l.id_lote) AS lotes,
                  SUM(l.cantidad_producida) AS unidades,
                  DATE(l.fecha_produccion) AS fecha
           FROM plantas p
           LEFT JOIN lotes l ON l.id_planta_origen = p.id_planta
           WHERE l.fecha_produccion >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
           GROUP BY p.nombre_planta, DATE(l.fecha_produccion)
           ORDER BY fecha DESC, p.nombre_planta'''
    )
    produccion = cursor.fetchall()

    cursor.close()
    conn.close()
    return render_template('reportes/index.html', stock=stock, vencimientos=vencimientos,
                           pedidos_pend=pedidos_pend, rotacion=rotacion, produccion=produccion)


@reportes_bp.route('/reportes/exportar/<tipo>')
@role_required([1, 2])
def exportar(tipo):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    if tipo == 'stock':
        cursor.execute('SELECT * FROM vista_stock_consolidado')
        rows = cursor.fetchall()
        headers = list(rows[0].keys()) if rows else ['Producto']
        filename = 'stock_consolidado_pil.csv'
    elif tipo == 'vencimientos':
        cursor.execute('SELECT * FROM vista_alertas_vencimiento')
        rows = cursor.fetchall()
        headers = list(rows[0].keys()) if rows else ['Numero_Lote']
        filename = 'alertas_vencimiento_pil.csv'
    elif tipo == 'pedidos':
        cursor.execute('SELECT * FROM vista_pedidos_pendientes')
        rows = cursor.fetchall()
        headers = list(rows[0].keys()) if rows else ['Nro_Pedido']
        filename = 'pedidos_pendientes_pil.csv'
    elif tipo == 'rotacion':
        cursor.execute(
            '''SELECT pr.nombre_comercial AS producto, pre.volumen AS presentacion,
                      COALESCE(SUM(CASE WHEN MONTH(m.fecha_movimiento)=MONTH(CURDATE()) AND m.tipo_movimiento='Salida' THEN m.cantidad ELSE 0 END),0) AS salidas_mes_actual,
                      COALESCE(SUM(CASE WHEN MONTH(m.fecha_movimiento)=MONTH(DATE_SUB(CURDATE(),INTERVAL 1 MONTH)) AND m.tipo_movimiento='Salida' THEN m.cantidad ELSE 0 END),0) AS salidas_mes_anterior
               FROM productos pr JOIN presentaciones pre ON pr.id_producto=pre.id_producto
               LEFT JOIN movimientos_inventario m ON m.id_presentacion=pre.id_presentacion
               GROUP BY pr.id_producto, pre.id_presentacion, pr.nombre_comercial, pre.volumen'''
        )
        rows = cursor.fetchall()
        headers = ['producto', 'presentacion', 'salidas_mes_actual', 'salidas_mes_anterior']
        filename = 'rotacion_inventario_pil.csv'
    elif tipo == 'produccion':
        cursor.execute(
            '''SELECT p.nombre_planta, DATE(l.fecha_produccion) AS fecha,
                      COUNT(l.id_lote) AS lotes, SUM(l.cantidad_producida) AS unidades
               FROM plantas p JOIN lotes l ON l.id_planta_origen=p.id_planta
               WHERE l.fecha_produccion >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
               GROUP BY p.nombre_planta, DATE(l.fecha_produccion)
               ORDER BY fecha DESC'''
        )
        rows = cursor.fetchall()
        headers = ['nombre_planta', 'fecha', 'lotes', 'unidades']
        filename = 'produccion_planta_pil.csv'
    else:
        cursor.close()
        conn.close()
        return 'Reporte no válido', 404

    cursor.close()
    conn.close()
    return csv_response(filename, headers, rows)
