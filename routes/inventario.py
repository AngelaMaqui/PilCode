from flask import Blueprint, render_template, request, redirect, url_for, flash, session, Response
import csv
import io
from database import get_db_connection
from utils.decorators import role_required

inventario_bp = Blueprint('inventario', __name__)

@inventario_bp.route('/stock')
@role_required([1, 2, 3])
def ver_stock():
    producto = request.args.get('producto', '').strip()
    planta = request.args.get('planta', '').strip()
    bodega = request.args.get('bodega', '').strip()
    estado = request.args.get('estado', '').strip()

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    sql = 'SELECT * FROM vista_stock_consolidado WHERE 1=1'
    params = []
    if producto:
        sql += ' AND Producto LIKE %s'
        params.append(f'%{producto}%')
    if planta:
        sql += ' AND Planta LIKE %s'
        params.append(f'%{planta}%')
    if bodega:
        sql += ' AND Bodega LIKE %s'
        params.append(f'%{bodega}%')
    if estado:
        sql += ' AND Estado_Inventario LIKE %s'
        params.append(f'%{estado}%')

    sql += ' ORDER BY Producto, Planta'
    cursor.execute(sql, params)
    productos_stock = cursor.fetchall()

    cursor.execute('SELECT DISTINCT Planta AS nombre FROM vista_stock_consolidado ORDER BY Planta')
    plantas = [r['nombre'] for r in cursor.fetchall()]
    cursor.execute('SELECT DISTINCT Bodega AS nombre FROM vista_stock_consolidado ORDER BY Bodega')
    bodegas = [r['nombre'] for r in cursor.fetchall()]
    cursor.execute('SELECT DISTINCT Estado_Inventario AS nombre FROM vista_stock_consolidado')
    estados = [r['nombre'] for r in cursor.fetchall()]

    cursor.execute(
        '''SELECT id_presentacion, codigo_presentacion, volumen FROM presentaciones ORDER BY id_presentacion'''
    )
    presentaciones = cursor.fetchall()
    cursor.execute('SELECT id_planta, nombre_planta FROM plantas ORDER BY id_planta')
    plantas_sel = cursor.fetchall()
    cursor.execute('SELECT id_bodega, nombre_bodega FROM bodegas ORDER BY id_bodega')
    bodegas_sel = cursor.fetchall()

    cursor.close()
    conn.close()
    return render_template(
        'inventario/stock.html', stock=productos_stock,
        plantas=plantas, bodegas=bodegas, estados=estados,
        presentaciones=presentaciones, plantas_sel=plantas_sel, bodegas_sel=bodegas_sel,
        filtro_producto=producto, filtro_planta=planta, filtro_bodega=bodega, filtro_estado=estado
    )


@inventario_bp.route('/lotes/registrar', methods=['POST'])
@role_required([1, 2])
def registrar_lote():
    """Invoca el Procedimiento Almacenado de Producción de Lotes de tu SQL"""
    numero_lote = request.form['numero_lote']
    id_presentacion = request.form['id_presentacion']
    id_planta = request.form['id_planta']
    id_bodega = request.form['id_bodega']
    fecha_prod = request.form['fecha_produccion']
    fecha_venc = request.form['fecha_vencimiento']
    cantidad = request.form['cantidad']
    tecnico = request.form['tecnico_responsable']
    id_usuario = session.get('user_id')  # El backend extrae automáticamente quién hace la acción

    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.callproc('sp_registrar_produccion_lote', [
            numero_lote, id_presentacion, id_planta, id_bodega, 
            fecha_prod, fecha_venc, cantidad, tecnico, id_usuario
        ])
        conn.commit()
        flash("Lote de producción procesado. El stock fue recalculado.", "success")
    except Exception as e:
        conn.rollback()  # Revierte la transacción en caso de errores de consistencia
        flash(f"Error al ejecutar el procedimiento: {str(e)}", "danger")
    finally:
        cursor.close()
        conn.close()
        
    return redirect(url_for('inventario.ver_stock'))


@inventario_bp.route('/reporte/vencimientos/csv')
@role_required([1, 2])
def exportar_vencimientos_csv():
    """Generación dinámica en memoria de reportes ejecutables exigidos en la rúbrica"""
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM vista_alertas_vencimiento")
    rows = cursor.fetchall()
    cursor.close()
    conn.close()

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(['Numero_Lote', 'Producto', 'Presentacion', 'Fecha_Vencimiento', 'Dias_Restantes', 'Nivel_Urgencia'])
    
    for row in rows:
        writer.writerow([
            row['Numero_Lote'], row['Producto'], row['Presentacion'], 
            row['Fecha_Vencimiento'], row['Dias_Restantes'], row['Nivel_Urgencia']
        ])
    
    output.seek(0)
    return Response(
        output.getvalue(),
        mimetype="text/csv",
        headers={"Content-disposition": "attachment; filename=alertas_vencimiento_pil.csv"}
    )