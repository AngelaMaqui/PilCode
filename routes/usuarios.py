from flask import Blueprint, render_template, request, redirect, url_for, flash
from werkzeug.security import generate_password_hash
from database import get_db_connection
from utils.decorators import role_required

usuarios_bp = Blueprint('usuarios', __name__)


@usuarios_bp.route('/admin/usuarios')
@role_required([1])
def listar():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute(
        '''SELECT u.id_usuario, u.username, u.nombre_completo, u.correo, u.activo,
                  u.fecha_creacion, r.nombre_rol, r.id_rol
           FROM usuarios u JOIN roles r ON u.id_rol = r.id_rol
           ORDER BY u.id_usuario'''
    )
    usuarios = cursor.fetchall()
    cursor.execute('SELECT * FROM roles ORDER BY id_rol')
    roles = cursor.fetchall()
    cursor.close()
    conn.close()
    return render_template('admin/usuarios.html', usuarios=usuarios, roles=roles)


@usuarios_bp.route('/admin/usuarios/crear', methods=['POST'])
@role_required([1])
def crear():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        h = generate_password_hash(request.form['password'], method='scrypt')
        cursor.execute(
            '''INSERT INTO usuarios (username, password_hash, nombre_completo, correo, id_rol, activo)
               VALUES (%s,%s,%s,%s,%s,%s)''',
            (request.form['username'], h, request.form['nombre_completo'],
             request.form['correo'], request.form['id_rol'], 1 if request.form.get('activo') else 0)
        )
        conn.commit()
        flash('Usuario creado correctamente.', 'success')
    except Exception as e:
        conn.rollback()
        flash(f'Error: {e}', 'danger')
    finally:
        cursor.close()
        conn.close()
    return redirect(url_for('usuarios.listar'))


@usuarios_bp.route('/admin/usuarios/<int:id_usuario>/editar', methods=['POST'])
@role_required([1])
def editar(id_usuario):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        if request.form.get('password'):
            h = generate_password_hash(request.form['password'], method='scrypt')
            cursor.execute(
                '''UPDATE usuarios SET username=%s, nombre_completo=%s, correo=%s,
                   id_rol=%s, activo=%s, password_hash=%s WHERE id_usuario=%s''',
                (request.form['username'], request.form['nombre_completo'], request.form['correo'],
                 request.form['id_rol'], 1 if request.form.get('activo') else 0, h, id_usuario)
            )
        else:
            cursor.execute(
                '''UPDATE usuarios SET username=%s, nombre_completo=%s, correo=%s,
                   id_rol=%s, activo=%s WHERE id_usuario=%s''',
                (request.form['username'], request.form['nombre_completo'], request.form['correo'],
                 request.form['id_rol'], 1 if request.form.get('activo') else 0, id_usuario)
            )
        conn.commit()
        flash('Usuario actualizado.', 'success')
    except Exception as e:
        conn.rollback()
        flash(f'Error: {e}', 'danger')
    finally:
        cursor.close()
        conn.close()
    return redirect(url_for('usuarios.listar'))


@usuarios_bp.route('/admin/usuarios/<int:id_usuario>/eliminar', methods=['POST'])
@role_required([1])
def eliminar(id_usuario):
    if id_usuario == 1:
        flash('No se puede eliminar el administrador principal.', 'warning')
        return redirect(url_for('usuarios.listar'))

    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute('UPDATE usuarios SET activo=0 WHERE id_usuario=%s', (id_usuario,))
        conn.commit()
        flash('Usuario desactivado.', 'success')
    except Exception as e:
        conn.rollback()
        flash(f'Error: {e}', 'danger')
    finally:
        cursor.close()
        conn.close()
    return redirect(url_for('usuarios.listar'))
