import mysql.connector
from mysql.connector import pooling
import os

# Para que funcione para los demas solo se debe realizar el
# cambio del password, el database y el puerto
db_config = {
    "host": "localhost",
    "user": "root",
    "password": "",
    "database": "pil_andina",
    "port": 3306
}

try:
    connection_pool = mysql.connector.pooling.MySQLConnectionPool(
        pool_name="pil_pool",
        pool_size=5,
        **db_config
    )
    print("Pool de conexiones de MySQL creado con éxito.")
except mysql.connector.Error as err:
    print(f"Error crítico al conectar con el Pool de MySQL: {err}")

def get_db_connection():
    """Entrega una conexión activa del Pool para ser usada en las rutas del servidor."""
    return connection_pool.get_connection()