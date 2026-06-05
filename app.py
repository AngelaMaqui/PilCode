import os
from flask import Flask, redirect, url_for
from routes.auth import auth_bp
from routes.inventario import inventario_bp
from routes.monitoreo import monitoreo_bp
from routes.backups import backups_bp
from werkzeug.security import generate_password_hash
import mysql.connector

app = Flask(__name__, template_folder=os.path.abspath('templates'))

app.secret_key = "seguridad_maxima_pil_andina_examen_backend"
app.register_blueprint(auth_bp, url_prefix='/auth')
app.register_blueprint(inventario_bp, url_prefix='/inventario')
app.register_blueprint(monitoreo_bp, url_prefix='/monitoreo')
app.register_blueprint(backups_bp, url_prefix='/backups')

@app.route('/')
def index():
    return redirect(url_for('auth.login'))

@app.route('/crear-usuario-fijo')
def crear_usuario_fijo():
    try:
        hash_nuevo = generate_password_hash('admin123', method='scrypt')
        conn = mysql.connector.connect(
            host="localhost",
            user="root",
            password="",
            database="pil_andina_db"
        )
        cursor = conn.cursor()
        sql = """INSERT INTO usuarios (username, password_hash, nombre_completo, correo, id_rol, activo) 
                 VALUES (%s, %s, %s, %s, %s, %s) 
                 ON DUPLICATE KEY UPDATE password_hash=%s"""
        
        valores = ('test_admin', hash_nuevo, 'Administrador de Pruebas', 'test@pil.bo', 1, 1, hash_nuevo)
        cursor.execute(sql, valores)
        conn.commit()
        
        cursor.close()
        conn.close()
        return "¡Usuario 'test_admin' creado o actualizado con éxito! Contraseña: admin123"
        
    except Exception as e:
        return f"Error al crear el usuario: {str(e)}"

if __name__ == '__main__':
    app.run(debug=True, port=5000)