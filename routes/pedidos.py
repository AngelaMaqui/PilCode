from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from database import get_db_connection
from utils.decorators import role_required

pedidos_bp = Blueprint('pedidos', __name__)


@pedidos_bp.route('/pedidos')
@role_required([1, 2, 3])
def listar():
    estado = request.args.get('estado', '').strip()
    distribuidor = request.args.get('distribuidor', '').strip()
    ciudad = request.args.get('ciudad', '').strip()

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    sql = '''SELECT pe.*, d.razon_social, d.ciudad, f.nro_factura, f.monto_total, f.estado_pago
             FROM pedidos pe
             JOIN distribuidores d ON pe.id_distribuidor = d.id_distribuidor
             LEFT JOIN facturas f ON f.id_pedido = pe.id_pedido
             WHERE 1=1'''
    params = []
    if estado:
        sql += ' AND pe.estado_pedido = %s'
        params.append(estado)
    if distribuidor:
        sql += ' AND d.razon_social LIKE %s'
        params.append(f'%{distribuidor}%')
    if ciudad:
        sql += ' AND d.ciudad = %s'
        params.append(ciudad)

    sql += ' ORDER BY pe.fecha_pedido DESC'
    cursor.execute(sql, params)
    pedidos = cursor.fetchall()

    cursor.execute('SELECT id_distribuidor, razon_social FROM distribuidores ORDER BY razon_social')
    distribuidores = cursor.fetchall()

    cursor.execute('SELECT DISTINCT ciudad FROM distribuidores ORDER BY ciudad')
    ciudades = [r['ciudad'] for r in cursor.fetchall()]

    cursor.execute(
        '''SELECT l.id_lote, l.numero_lote_unico, pr.nombre_comercial, pre.volumen
           FROM lotes l
           JOIN presentaciones pre ON l.id_presentacion = pre.id_presentacion
           JOIN productos pr ON pre.id_producto = pr.id_producto
           WHERE l.estado_calidad = 'Aprobado'
           ORDER BY l.fecha_vencimiento'''
    )
    lotes = cursor.fetchall()

    cursor.execute('SELECT id_bodega, nombre_bodega FROM bodegas ORDER BY nombre_bodega')
    bodegas = cursor.fetchall()

    cursor.execute(
        '''SELECT pr.id_presentacion, p.nombre_comercial, pr.volumen, pr.codigo_presentacion
           FROM presentaciones pr JOIN productos p ON pr.id_producto=p.id_producto
           ORDER BY p.nombre_comercial'''
    )
    presentaciones = cursor.fetchall()

    cursor.close()
    conn.close()
    return render_template('pedidos/listar.html', pedidos=pedidos, distribuidores=distribuidores,
                           ciudades=ciudades, lotes=lotes, bodegas=bodegas, presentaciones=presentaciones,
                           estado_filtro=estado, distribuidor_filtro=distribuidor, ciudad_filtro=ciudad)


@pedidos_bp.route('/pedidos/crear', methods=['POST'])
@role_required([1, 2, 3])
def crear():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            '''INSERT INTO pedidos (id_distribuidor, fecha_pedido, fecha_entrega_requerida, estado_pedido)
               VALUES (%s, NOW(), %s, 'Pendiente')''',
            (request.form['id_distribuidor'], request.form['fecha_entrega_requerida'])
        )
        id_pedido = cursor.lastrowid

        id_presentacion = request.form['id_presentacion']
        cantidad = request.form['cantidad_solicitada']

        cursor.execute('SELECT precio_actual FROM productos p JOIN presentaciones pr ON p.id_producto=pr.id_producto WHERE pr.id_presentacion=%s', (id_presentacion,))
        precio = cursor.fetchone()[0]

        cursor.execute(
            'INSERT INTO detalle_pedidos (id_pedido, id_presentacion, cantidad_solicitada, precio_unitario_historico) VALUES (%s,%s,%s,%s)',
            (id_pedido, id_presentacion, cantidad, precio)
        )

        monto = float(precio) * int(cantidad)
        nro_factura = f"FAC-{id_pedido:04d}"
        cursor.execute(
            'INSERT INTO facturas (id_pedido, nro_factura, monto_total, estado_pago, fecha_emision) VALUES (%s,%s,%s,%s,NOW())',
            (id_pedido, nro_factura, monto, 'Pendiente')
        )

        conn.commit()
        flash(f'Pedido #{id_pedido} creado con factura {nro_factura}.', 'success')
    except Exception as e:
        conn.rollback()
        flash(f'Error al crear pedido: {e}', 'danger')
    finally:
        cursor.close()
        conn.close()
    return redirect(url_for('pedidos.listar'))


@pedidos_bp.route('/pedidos/<int:id_pedido>/despachar', methods=['POST'])
@role_required([1, 2])
def despachar(id_pedido):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.callproc('sp_despachar_pedido', [
            id_pedido,
            int(request.form['id_bodega_origen']),
            int(request.form['id_lote_despacho']),
            session.get('user_id')
        ])
        conn.commit()
        flash(f'Pedido #{id_pedido} despachado correctamente.', 'success')
    except Exception as e:
        conn.rollback()
        flash(f'Error al despachar: {e}', 'danger')
    finally:
        cursor.close()
        conn.close()
    return redirect(url_for('pedidos.listar'))


@pedidos_bp.route('/pedidos/<int:id_pedido>/estado', methods=['POST'])
@role_required([1, 2])
def cambiar_estado(id_pedido):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            'UPDATE pedidos SET estado_pedido=%s WHERE id_pedido=%s',
            (request.form['estado_pedido'], id_pedido)
        )
        if request.form.get('estado_pago'):
            cursor.execute(
                'UPDATE facturas SET estado_pago=%s WHERE id_pedido=%s',
                (request.form['estado_pago'], id_pedido)
            )
        conn.commit()
        flash('Estado actualizado.', 'success')
    except Exception as e:
        conn.rollback()
        flash(f'Error: {e}', 'danger')
    finally:
        cursor.close()
        conn.close()
    return redirect(url_for('pedidos.listar'))
