from flask import Blueprint, render_template, request, redirect, url_for, session, flash

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
 
        if username == 'admin_pil' and password == 'admin123':
            session['user_id'] = 1
            session['username'] = 'admin_pil'
            session['role_id'] = 1  # Rol 1: Administrador (Acceso total)
            flash("¡Bypass Administrador activado!", "success")
            return redirect(url_for('inventario.ver_stock'))

        elif username == 'carlos_gerente' and password == 'gerente123':
            session['user_id'] = 2
            session['username'] = 'carlos_gerente'
            session['role_id'] = 2  # Rol 2: Gerente (Dashboard y Reportes)
            flash("¡Bypass Gerente activado!", "success")
            return redirect(url_for('inventario.ver_stock'))

        elif username == 'dist_tiendas_bolivia' and password == 'dist123':
            session['user_id'] = 3
            session['username'] = 'dist_tiendas_bolivia'
            session['role_id'] = 3 
            flash("¡Bypass Distribuidor activado!", "success")
            return redirect(url_for('inventario.ver_stock'))
        
        flash("Credenciales incorrectas o usuario no válido.", "danger")
            
    return render_template('login.html')

@auth_bp.route('/logout')
def logout():
    session.clear()
    flash("Sesión cerrada correctamente.", "info")
    return redirect(url_for('auth.login'))