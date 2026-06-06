import mysql.connector
from mysql.connector import pooling

db_config = {
    "host": "localhost",
    "user": "root",
    "password": "superadministrador", 
    "database": "empresa_pil_andina",
    "port": 3308
}

connection_pool = None

try:
    connection_pool = pooling.MySQLConnectionPool(
        pool_name="pil_pool",
        pool_size=5,
        **db_config
    )
    print("==================================================")
    print(" ¡POOL DE CONEXIONES DE MYSQL CREADO CON ÉXITO!")
    print("==================================================")
except mysql.connector.Error as err:
    print("==================================================")
    print(f"❌ ERROR CRÍTICO EN MYSQL: {err}")
    print("Asegúrate de que XAMPP o WampServer tengan el MySQL encendido en el puerto 3308.")
    print("==================================================")
    connection_pool = None

def get_db_connection():
    """Entrega una conexión activa del Pool para validar las credenciales."""
    global connection_pool
    if connection_pool is None:
        raise Exception("El pool de conexiones no se pudo inicializar. Revisa que tu XAMPP/WampServer esté corriendo en el puerto 3308.")
    return connection_pool.get_connection()