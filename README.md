# PIL Andina — Sistema de Gestión de Inventario y Distribución

Proyecto integrador Base de Datos 2 — Cervecería Boliviana PIL Andina.

**Repositorio:** https://github.com/AngelaMaqui/PilCode

## Integrantes
- Nombre: Annett Abigail Luna Quispe         CI: 8482243		  Rol: Backend Developer
- Nombre: Angela Victoria Maqui Quispe       CI: 13694497	  Rol: DBA (Administrador BD)
- Nombre: Eva Jhenny Tola Huanca             CI: 9903814      Rol: Frontend Developer


## Requisitos
- Python 3.10+
- MySQL 8.x (XAMPP o similar)
- `mysqldump` y `mysql` en el PATH

## Instalación

1. Clonar el repositorio
2. Crear entorno virtual e instalar dependencias:
   ```bash
   pip install -r requirements.txt
   ```
3. Importar la base de datos:
   ```bash
   mysql -u root -p < sql/pil_andina_schema.sql
   ```
   Para regenerar el script SQL desde la BD activa:
   ```bash
   python scripts/exportar_schema.py
   ```
4. Configurar conexión en `database.py` (host, user, password, port)
5. Sincronizar credenciales de demostración:
   ```bash
   python init_credenciales.py
   ```
6. Ejecutar la aplicación:
   ```bash
   python app.py
   ```
7. Abrir http://127.0.0.1:5000

## Credenciales de acceso

|      Usuario         | Contraseña |    Rol        |
|----------------------|------------|---------------|
| admin_pil            | admin123   | Administrador |
| carlos_gerente       | gerente123 | Gerente       |
| dist_tiendas_bolivia | dist123    | Distribuidor  |

## Módulos implementados

- **Dashboard** — Métricas y gráficos (Chart.js)
- **Productos** — CRUD completo + presentaciones
- **Plantas y Bodegas** — Gestión de bodegas por planta
- **Inventario** — Stock consolidado, filtros, registro de lotes (SP)
- **Distribuidores** — CRUD con búsqueda avanzada
- **Pedidos** — Creación, despacho (SP), facturación
- **Reportes** — 5 reportes exportables a CSV
- **Usuarios** — Panel de administración de usuarios y roles
- **Backups** — Crear, listar y restaurar respaldos
- **Monitoreo** — Conexiones, procesos, EXPLAIN, logs de auditoría

## Estructura del proyecto

```
app.py              # Punto de entrada Flask
database.py         # Pool de conexiones MySQL
routes/             # Blueprints por módulo
templates/          # Vistas HTML (Jinja2)
static/             # CSS y JS
sql/                # Scripts y documentación BD
scripts/            # Backup programado
backups/            # Respaldos generados
```

## Backup programado

Ejecutar `scripts/backup_programado.bat` o programarlo en el Programador de tareas de Windows.
