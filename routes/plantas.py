from flask import Blueprint, render_template, request, redirect, url_for, flash
from database import get_db_connection
from utils.decorators import role_required

plantas_bp = Blueprint('plantas', __name__)


@plantas_bp.route('/plantas')
@role_required([1, 2, 3])
def listar():
    planta_id = request.args.get('planta', '').strip()
    tipo_bodega = request.args.get('tipo_bodega', '').strip()

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute('SELECT * FROM plantas ORDER BY id_planta')
    plantas = cursor.fetchall()

    sql = '''SELECT b.*, p.nombre_planta, p.ubicacion_especifica
             FROM bodegas b JOIN plantas p ON b.id_planta = p.id_planta WHERE 1=1'''
    params = []
    if planta_id:
        sql += ' AND b.id_planta = %s'
        params.append(planta_id)
    if tipo_bodega:
        sql += ' AND b.nombre_bodega LIKE %s'
        params.append(f'%{tipo_bodega}%')

    sql += ' ORDER BY p.nombre_planta, b.nombre_bodega'
    cursor.execute(sql, params)
    bodegas = cursor.fetchall()

    cursor.close()
    conn.close()
    return render_template('plantas/listar.html', plantas=plantas, bodegas=bodegas,
                           planta_filtro=planta_id, tipo_bodega_filtro=tipo_bodega)


@plantas_bp.route('/plantas/bodega/crear', methods=['POST'])
@role_required([1, 2])
def crear_bodega():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            '''INSERT INTO bodegas (id_planta, nombre_bodega, capacidad_maxima, temperatura_almacenamiento)
               VALUES (%s,%s,%s,%s)''',
            (request.form['id_planta'], request.form['nombre_bodega'],
             request.form['capacidad_maxima'], request.form['temperatura_almacenamiento'])
        )
        conn.commit()
        flash('Bodega registrada.', 'success')
    except Exception as e:
        conn.rollback()
        flash(f'Error: {e}', 'danger')
    finally:
        cursor.close()
        conn.close()
    return redirect(url_for('plantas.listar'))


@plantas_bp.route('/plantas/bodega/<int:id_bodega>/editar', methods=['POST'])
@role_required([1, 2])
def editar_bodega(id_bodega):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            '''UPDATE bodegas SET id_planta=%s, nombre_bodega=%s, capacidad_maxima=%s,
               temperatura_almacenamiento=%s WHERE id_bodega=%s''',
            (request.form['id_planta'], request.form['nombre_bodega'],
             request.form['capacidad_maxima'], request.form['temperatura_almacenamiento'], id_bodega)
        )
        conn.commit()
        flash('Bodega actualizada.', 'success')
    except Exception as e:
        conn.rollback()
        flash(f'Error: {e}', 'danger')
    finally:
        cursor.close()
        conn.close()
    return redirect(url_for('plantas.listar'))


@plantas_bp.route('/plantas/bodega/<int:id_bodega>/eliminar', methods=['POST'])
@role_required([1])
def eliminar_bodega(id_bodega):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute('DELETE FROM bodegas WHERE id_bodega=%s', (id_bodega,))
        conn.commit()
        flash('Bodega eliminada.', 'success')
    except Exception as e:
        conn.rollback()
        flash(f'No se pudo eliminar: {e}', 'danger')
    finally:
        cursor.close()
        conn.close()
    return redirect(url_for('plantas.listar'))
