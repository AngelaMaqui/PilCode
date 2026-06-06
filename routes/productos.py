from flask import Blueprint, render_template, request, redirect, url_for, flash
from database import get_db_connection
from utils.decorators import role_required

productos_bp = Blueprint('productos', __name__)


@productos_bp.route('/productos')
@role_required([1, 2, 3])
def listar():
    q = request.args.get('q', '').strip()
    tipo = request.args.get('tipo', '').strip()

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    sql = 'SELECT * FROM productos WHERE 1=1'
    params = []
    if q:
        sql += ' AND (nombre_comercial LIKE %s OR codigo_unico LIKE %s)'
        params.extend([f'%{q}%', f'%{q}%'])
    if tipo:
        sql += ' AND tipo_cerveza = %s'
        params.append(tipo)

    sql += ' ORDER BY nombre_comercial'
    cursor.execute(sql, params)
    productos = cursor.fetchall()

    cursor.execute('SELECT DISTINCT tipo_cerveza FROM productos ORDER BY tipo_cerveza')
    tipos = [r['tipo_cerveza'] for r in cursor.fetchall()]

    cursor.execute(
        '''SELECT pr.*, p.nombre_comercial
           FROM presentaciones pr JOIN productos p ON pr.id_producto = p.id_producto
           ORDER BY p.nombre_comercial, pr.volumen'''
    )
    presentaciones = cursor.fetchall()

    cursor.close()
    conn.close()
    return render_template('productos/listar.html', productos=productos, presentaciones=presentaciones, tipos=tipos, q=q, tipo_filtro=tipo)


@productos_bp.route('/productos/crear', methods=['GET', 'POST'])
@role_required([1, 2])
def crear():
    if request.method == 'POST':
        conn = get_db_connection()
        cursor = conn.cursor()
        try:
            cursor.execute(
                '''INSERT INTO productos (codigo_unico, nombre_comercial, tipo_cerveza,
                   graduacion_alcoholica, precio_actual, stock_minimo_alerta, stock_maximo_alerta)
                   VALUES (%s,%s,%s,%s,%s,%s,%s)''',
                (request.form['codigo_unico'], request.form['nombre_comercial'], request.form['tipo_cerveza'],
                 request.form['graduacion_alcoholica'], request.form['precio_actual'],
                 request.form['stock_minimo_alerta'], request.form['stock_maximo_alerta'])
            )
            conn.commit()
            flash('Producto registrado correctamente.', 'success')
            return redirect(url_for('productos.listar'))
        except Exception as e:
            conn.rollback()
            flash(f'Error al crear producto: {e}', 'danger')
        finally:
            cursor.close()
            conn.close()

    return render_template('productos/form.html', producto=None, accion='crear')


@productos_bp.route('/productos/<int:id_producto>/editar', methods=['GET', 'POST'])
@role_required([1, 2])
def editar(id_producto):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    if request.method == 'POST':
        try:
            cursor.execute(
                '''UPDATE productos SET codigo_unico=%s, nombre_comercial=%s, tipo_cerveza=%s,
                   graduacion_alcoholica=%s, precio_actual=%s, stock_minimo_alerta=%s, stock_maximo_alerta=%s
                   WHERE id_producto=%s''',
                (request.form['codigo_unico'], request.form['nombre_comercial'], request.form['tipo_cerveza'],
                 request.form['graduacion_alcoholica'], request.form['precio_actual'],
                 request.form['stock_minimo_alerta'], request.form['stock_maximo_alerta'], id_producto)
            )
            conn.commit()
            flash('Producto actualizado.', 'success')
            return redirect(url_for('productos.listar'))
        except Exception as e:
            conn.rollback()
            flash(f'Error al actualizar: {e}', 'danger')

    cursor.execute('SELECT * FROM productos WHERE id_producto=%s', (id_producto,))
    producto = cursor.fetchone()
    cursor.close()
    conn.close()

    if not producto:
        flash('Producto no encontrado.', 'warning')
        return redirect(url_for('productos.listar'))

    return render_template('productos/form.html', producto=producto, accion='editar')


@productos_bp.route('/productos/<int:id_producto>/eliminar', methods=['POST'])
@role_required([1])
def eliminar(id_producto):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute('DELETE FROM productos WHERE id_producto=%s', (id_producto,))
        conn.commit()
        flash('Producto eliminado.', 'success')
    except Exception as e:
        conn.rollback()
        flash(f'No se pudo eliminar (tiene dependencias): {e}', 'danger')
    finally:
        cursor.close()
        conn.close()
    return redirect(url_for('productos.listar'))


@productos_bp.route('/productos/presentacion/crear', methods=['POST'])
@role_required([1, 2])
def crear_presentacion():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            'INSERT INTO presentaciones (id_producto, codigo_presentacion, empaque, volumen) VALUES (%s,%s,%s,%s)',
            (request.form['id_producto'], request.form['codigo_presentacion'],
             request.form['empaque'], request.form['volumen'])
        )
        conn.commit()
        flash('Presentación agregada.', 'success')
    except Exception as e:
        conn.rollback()
        flash(f'Error: {e}', 'danger')
    finally:
        cursor.close()
        conn.close()
    return redirect(url_for('productos.listar'))
