from flask import Blueprint, render_template, request, redirect, url_for, flash
from database import get_db_connection
from utils.decorators import role_required

distribuidores_bp = Blueprint('distribuidores', __name__)


@distribuidores_bp.route('/distribuidores')
@role_required([1, 2, 3])
def listar():
    ciudad = request.args.get('ciudad', '').strip()
    zona = request.args.get('zona', '').strip()
    q = request.args.get('q', '').strip()

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    sql = 'SELECT * FROM distribuidores WHERE 1=1'
    params = []
    if q:
        sql += ' AND (razon_social LIKE %s OR nit LIKE %s OR contacto_nombre LIKE %s)'
        params.extend([f'%{q}%', f'%{q}%', f'%{q}%'])
    if ciudad:
        sql += ' AND ciudad = %s'
        params.append(ciudad)
    if zona:
        sql += ' AND zona = %s'
        params.append(zona)

    sql += ' ORDER BY razon_social'
    cursor.execute(sql, params)
    distribuidores = cursor.fetchall()

    cursor.execute('SELECT DISTINCT ciudad FROM distribuidores ORDER BY ciudad')
    ciudades = [r['ciudad'] for r in cursor.fetchall()]
    cursor.execute('SELECT DISTINCT zona FROM distribuidores ORDER BY zona')
    zonas = [r['zona'] for r in cursor.fetchall()]

    cursor.close()
    conn.close()
    return render_template('distribuidores/listar.html', distribuidores=distribuidores,
                           ciudades=ciudades, zonas=zonas, q=q, ciudad_filtro=ciudad, zona_filtro=zona)


@distribuidores_bp.route('/distribuidores/crear', methods=['GET', 'POST'])
@role_required([1, 2])
def crear():
    if request.method == 'POST':
        conn = get_db_connection()
        cursor = conn.cursor()
        try:
            cursor.execute(
                '''INSERT INTO distribuidores (nit, razon_social, direccion, ciudad, zona,
                   contacto_nombre, telefono, correo) VALUES (%s,%s,%s,%s,%s,%s,%s,%s)''',
                (request.form['nit'], request.form['razon_social'], request.form['direccion'],
                 request.form['ciudad'], request.form['zona'], request.form['contacto_nombre'],
                 request.form['telefono'], request.form['correo'])
            )
            conn.commit()
            flash('Distribuidor registrado.', 'success')
            return redirect(url_for('distribuidores.listar'))
        except Exception as e:
            conn.rollback()
            flash(f'Error: {e}', 'danger')
        finally:
            cursor.close()
            conn.close()
    return render_template('distribuidores/form.html', distribuidor=None, accion='crear')


@distribuidores_bp.route('/distribuidores/<int:id_distribuidor>/editar', methods=['GET', 'POST'])
@role_required([1, 2])
def editar(id_distribuidor):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    if request.method == 'POST':
        try:
            cursor.execute(
                '''UPDATE distribuidores SET nit=%s, razon_social=%s, direccion=%s, ciudad=%s,
                   zona=%s, contacto_nombre=%s, telefono=%s, correo=%s WHERE id_distribuidor=%s''',
                (request.form['nit'], request.form['razon_social'], request.form['direccion'],
                 request.form['ciudad'], request.form['zona'], request.form['contacto_nombre'],
                 request.form['telefono'], request.form['correo'], id_distribuidor)
            )
            conn.commit()
            flash('Distribuidor actualizado.', 'success')
            return redirect(url_for('distribuidores.listar'))
        except Exception as e:
            conn.rollback()
            flash(f'Error: {e}', 'danger')

    cursor.execute('SELECT * FROM distribuidores WHERE id_distribuidor=%s', (id_distribuidor,))
    distribuidor = cursor.fetchone()
    cursor.close()
    conn.close()

    if not distribuidor:
        flash('Distribuidor no encontrado.', 'warning')
        return redirect(url_for('distribuidores.listar'))

    return render_template('distribuidores/form.html', distribuidor=distribuidor, accion='editar')


@distribuidores_bp.route('/distribuidores/<int:id_distribuidor>/eliminar', methods=['POST'])
@role_required([1])
def eliminar(id_distribuidor):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute('DELETE FROM distribuidores WHERE id_distribuidor=%s', (id_distribuidor,))
        conn.commit()
        flash('Distribuidor eliminado.', 'success')
    except Exception as e:
        conn.rollback()
        flash(f'No se pudo eliminar: {e}', 'danger')
    finally:
        cursor.close()
        conn.close()
    return redirect(url_for('distribuidores.listar'))
