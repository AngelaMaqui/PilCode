from flask import Blueprint, render_template, request, redirect, url_for, session, flash
from werkzeug.security import check_password_hash
from database import get_db_connection

auth_bp = Blueprint('auth', __name__)


@auth_bp.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username'].strip()
        password = request.form['password']

        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            '''SELECT u.id_usuario, u.username, u.password_hash, u.id_rol, r.nombre_rol
               FROM usuarios u JOIN roles r ON u.id_rol = r.id_rol
               WHERE u.username = %s AND u.activo = 1''',
            (username,)
        )
        user = cursor.fetchone()
        cursor.close()
        conn.close()

        if user and user['password_hash'] and check_password_hash(user['password_hash'], password):
            session['user_id'] = user['id_usuario']
            session['username'] = user['username']
            session['role_id'] = user['id_rol']
            session['role_name'] = user['nombre_rol']
            flash(f"Bienvenido, {user['username']} ({user['nombre_rol']})", "success")
            return redirect(url_for('dashboard.index'))

        flash("Credenciales incorrectas o usuario inactivo.", "danger")

    return render_template('login.html')


@auth_bp.route('/logout')
def logout():
    session.clear()
    flash("Sesión cerrada correctamente.", "info")
    return redirect(url_for('auth.login'))
