from functools import wraps
from flask import session, flash, redirect, url_for

def role_required(allowed_roles):
    """
    Controlador de acceso seguro basado en Roles de PIL Andina
    Roles permitidos: 1 = Administrador, 2 = Gerente, 3 = Distribuidor
    """
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if 'user_id' not in session:
                flash("Por favor, inicia sesión para acceder al sistema.", "danger")
                return redirect(url_for('auth.login'))

            if session.get('role_id') not in allowed_roles:
                flash("No tienes los privilegios necesarios para acceder a este módulo.", "warning")
                return redirect(url_for('auth.login'))
                
            return f(*args, **kwargs)
        return decorated_function
    return decorator