import os
from flask import Flask, redirect, url_for
from routes.auth import auth_bp
from routes.dashboard import dashboard_bp
from routes.inventario import inventario_bp
from routes.productos import productos_bp
from routes.distribuidores import distribuidores_bp
from routes.plantas import plantas_bp
from routes.pedidos import pedidos_bp
from routes.reportes import reportes_bp
from routes.monitoreo import monitoreo_bp
from routes.backups import backups_bp
from routes.usuarios import usuarios_bp

app = Flask(__name__, template_folder=os.path.abspath('templates'))
app.secret_key = "seguridad_maxima_pil_andina_examen_backend"

app.register_blueprint(auth_bp, url_prefix='/auth')
app.register_blueprint(dashboard_bp)
app.register_blueprint(inventario_bp, url_prefix='/inventario')
app.register_blueprint(productos_bp)
app.register_blueprint(distribuidores_bp)
app.register_blueprint(plantas_bp)
app.register_blueprint(pedidos_bp)
app.register_blueprint(reportes_bp)
app.register_blueprint(monitoreo_bp, url_prefix='/monitoreo')
app.register_blueprint(backups_bp, url_prefix='/backups')
app.register_blueprint(usuarios_bp)


@app.route('/')
def index():
    return redirect(url_for('auth.login'))


if __name__ == '__main__':
    app.run(debug=True, port=5000)
