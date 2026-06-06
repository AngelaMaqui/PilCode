"""Ejecutar una vez para sincronizar contraseñas de demostración con la BD."""
from werkzeug.security import generate_password_hash
from database import get_db_connection

DEMO_USERS = {
    'admin_pil': 'admin123',
    'carlos_gerente': 'gerente123',
    'dist_tiendas_bolivia': 'dist123',
}

if __name__ == '__main__':
    conn = get_db_connection()
    cursor = conn.cursor()
    for username, password in DEMO_USERS.items():
        h = generate_password_hash(password, method='scrypt')
        cursor.execute(
            'UPDATE usuarios SET password_hash=%s WHERE username=%s',
            (h, username)
        )
        print(f'Actualizado: {username}')
    conn.commit()
    cursor.close()
    conn.close()
    print('Credenciales de demostración listas.')
