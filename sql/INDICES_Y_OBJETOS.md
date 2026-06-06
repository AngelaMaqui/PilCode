# Objetos de Base de Datos — PIL Andina

## Tablas (14)
`productos`, `presentaciones`, `plantas`, `bodegas`, `lotes`, `inventario_bodega`, `movimientos_inventario`, `distribuidores`, `pedidos`, `detalle_pedidos`, `facturas`, `usuarios`, `roles`, `logs_auditoria`

## Vistas (3)
- `vista_stock_consolidado` — Stock por producto, planta y bodega
- `vista_alertas_vencimiento` — Productos próximos a vencer (30/15/7 días)
- `vista_pedidos_pendientes` — Pedidos pendientes con facturación

## Procedimientos almacenados (2)
- `sp_registrar_produccion_lote` — Registra lote y actualiza inventario
- `sp_despachar_pedido` — Despacha pedido y registra movimiento de salida

## Triggers (2)
- `tr_control_stock_automatico` — Control de stock en movimientos
- `tr_auditoria_precios_productos` — Auditoría de cambios de precio

## Índices estratégicos (justificación)
1. **Índice en `lotes.fecha_vencimiento`** — Acelera consultas de alertas de vencimiento (vista_alertas_vencimiento)
2. **Índice en `pedidos.estado_pedido`** — Filtra pedidos pendientes frecuentemente
3. **Índice en `productos.codigo_unico`** — Búsqueda rápida por código de producto en CRUD

## Roles MySQL / Aplicación
| Rol | ID | Permisos en la app |
|-----|----|--------------------|
| Administrador | 1 | Acceso total + usuarios + backups + monitoreo |
| Gerente | 2 | Dashboard, CRUD, reportes, inventario |
| Distribuidor | 3 | Consulta stock, crear pedidos |

## Instalación BD
```bash
mysql -u root -p < sql/pil_andina_schema.sql
python init_credenciales.py
```
