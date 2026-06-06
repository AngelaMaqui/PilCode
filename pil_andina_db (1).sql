-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 05-06-2026 a las 19:07:33
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `pil_andina_db`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_despachar_pedido` (IN `p_id_pedido` INT, IN `p_id_bodega_origen` INT, IN `p_id_lote_despacho` INT, IN `p_id_usuario` INT)   BEGIN

    DECLARE v_finalizado INT DEFAULT 0;
    DECLARE v_id_presentacion INT;
    DECLARE v_cantidad_solicitada INT;

    DECLARE cursor_pedido CURSOR FOR 
        SELECT id_presentacion, cantidad_solicitada 
        FROM detalle_pedidos 
        WHERE id_pedido = p_id_pedido;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_finalizado = 1;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error al procesar el despacho. Verifique datos o inventario.';
    END;

    START TRANSACTION;

    UPDATE pedidos 
    SET estado_pedido = 'Despachado' 
    WHERE id_pedido = p_id_pedido;

    OPEN cursor_pedido;
    
    FETCH cursor_pedido INTO v_id_presentacion, v_cantidad_solicitada;

    WHILE v_finalizado = 0 DO

        INSERT INTO movimientos_inventario (
            id_bodega_origen, id_bodega_destino, id_presentacion, 
            id_lote, id_usuario, tipo_movimiento, cantidad
        ) 
        VALUES (
            p_id_bodega_origen, NULL, v_id_presentacion, 
            p_id_lote_despacho, p_id_usuario, 'Salida por Venta', v_cantidad_solicitada
        );

        FETCH cursor_pedido INTO v_id_presentacion, v_cantidad_solicitada;
    END WHILE;
    
    CLOSE cursor_pedido;

    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_produccion_lote` (IN `p_numero_lote` VARCHAR(50), IN `p_id_presentacion` INT, IN `p_id_planta` INT, IN `p_id_bodega` INT, IN `p_fecha_prod` DATE, IN `p_fecha_venc` DATE, IN `p_cantidad` INT, IN `p_tecnico` VARCHAR(100), IN `p_id_usuario` INT)   BEGIN

    DECLARE v_id_lote INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error al registrar la producción. Transacción cancelada.';
    END;

    START TRANSACTION;

    INSERT INTO lotes (
        numero_lote_unico, id_presentacion, id_planta_origen, 
        fecha_produccion, fecha_vencimiento, cantidad_producida, tecnico_responsable
    ) 
    VALUES (
        p_numero_lote, p_id_presentacion, p_id_planta, 
        p_fecha_prod, p_fecha_venc, p_cantidad, p_tecnico
    );

    SET v_id_lote = LAST_INSERT_ID();

    INSERT INTO movimientos_inventario (
        id_bodega_origen, id_bodega_destino, id_presentacion, 
        id_lote, id_usuario, tipo_movimiento, cantidad
    ) 
    VALUES (
        NULL, p_id_bodega, p_id_presentacion, 
        v_id_lote, p_id_usuario, 'Entrada por Produccion', p_cantidad
    );

    COMMIT;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `bodegas`
--

CREATE TABLE `bodegas` (
  `id_bodega` int(11) NOT NULL,
  `id_planta` int(11) NOT NULL,
  `nombre_bodega` varchar(100) NOT NULL,
  `capacidad_maxima` int(11) NOT NULL,
  `temperatura_almacenamiento` decimal(4,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `bodegas`
--

INSERT INTO `bodegas` (`id_bodega`, `id_planta`, `nombre_bodega`, `capacidad_maxima`, `temperatura_almacenamiento`) VALUES
(1, 1, 'Producto Terminado', 50000, 12.50),
(2, 1, 'Insumos', 20000, 20.00),
(3, 1, 'Refrigerado', 15000, 4.00),
(4, 2, 'Producto Terminado', 60000, 14.00),
(5, 2, 'Insumos', 25000, 22.00),
(6, 2, 'Refrigerado', 20000, 5.00),
(7, 3, 'Producto Terminado', 80000, 15.00),
(8, 3, 'Insumos', 35000, 25.00),
(9, 3, 'Refrigerado', 30000, 3.50);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_pedidos`
--

CREATE TABLE `detalle_pedidos` (
  `id_detalle` int(11) NOT NULL,
  `id_pedido` int(11) NOT NULL,
  `id_presentacion` int(11) NOT NULL,
  `cantidad_solicitada` int(11) NOT NULL,
  `precio_unitario_historico` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `detalle_pedidos`
--

INSERT INTO `detalle_pedidos` (`id_detalle`, `id_pedido`, `id_presentacion`, `cantidad_solicitada`, `precio_unitario_historico`) VALUES
(1, 1, 2, 500, 12.00);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `distribuidores`
--

CREATE TABLE `distribuidores` (
  `id_distribuidor` int(11) NOT NULL,
  `nit` varchar(30) NOT NULL,
  `razon_social` varchar(150) NOT NULL,
  `direccion` varchar(255) NOT NULL,
  `ciudad` varchar(50) NOT NULL,
  `zona` varchar(100) NOT NULL,
  `contacto_nombre` varchar(100) NOT NULL,
  `telefono` varchar(30) NOT NULL,
  `correo` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `distribuidores`
--

INSERT INTO `distribuidores` (`id_distribuidor`, `nit`, `razon_social`, `direccion`, `ciudad`, `zona`, `contacto_nombre`, `telefono`, `correo`) VALUES
(1, '1020304021', 'Distribuidora Tiendas Bolivia S.A.', 'Av. Blanco Galindo Km 4', 'Cochabamba', 'Norte', 'Juan Carlos Perez', '4452211', 'pedidos@tiendasbolivia.com.bo'),
(2, '5493021015', 'Comercializadora Norte La Paz', 'Av. Juan Pablo II Nro 150', 'La Paz', 'El Alto', 'Elena Quispe', '2284455', 'contacto@comercialnorte.com');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `facturas`
--

CREATE TABLE `facturas` (
  `id_factura` int(11) NOT NULL,
  `id_pedido` int(11) NOT NULL,
  `nro_factura` varchar(50) NOT NULL,
  `monto_total` decimal(10,2) NOT NULL,
  `estado_pago` enum('Pendiente','Pagado','Anulado') DEFAULT 'Pendiente',
  `fecha_emision` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `facturas`
--

INSERT INTO `facturas` (`id_factura`, `id_pedido`, `nro_factura`, `monto_total`, `estado_pago`, `fecha_emision`) VALUES
(1, 1, 'FAC-2026-0001', 6000.00, 'Pendiente', '2026-06-05 16:49:22');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `inventario_bodega`
--

CREATE TABLE `inventario_bodega` (
  `id_inventario` int(11) NOT NULL,
  `id_bodega` int(11) NOT NULL,
  `id_presentacion` int(11) NOT NULL,
  `id_lote` int(11) NOT NULL,
  `stock_actual` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `inventario_bodega`
--

INSERT INTO `inventario_bodega` (`id_inventario`, `id_bodega`, `id_presentacion`, `id_lote`, `stock_actual`) VALUES
(1, 1, 2, 1, 4000),
(2, 4, 4, 2, 3000),
(3, 7, 5, 3, 4000);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `logs_auditoria`
--

CREATE TABLE `logs_auditoria` (
  `id_log` int(11) NOT NULL,
  `tabla_afectada` varchar(50) NOT NULL,
  `accion_realizada` enum('INSERT','UPDATE','DELETE') NOT NULL,
  `id_registro_afectado` int(11) NOT NULL,
  `valores_anteriores` text DEFAULT NULL,
  `valores_nuevos` text DEFAULT NULL,
  `usuario_bd` varchar(50) NOT NULL,
  `fecha_accion` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `lotes`
--

CREATE TABLE `lotes` (
  `id_lote` int(11) NOT NULL,
  `numero_lote_unico` varchar(50) NOT NULL,
  `id_presentacion` int(11) NOT NULL,
  `id_planta_origen` int(11) NOT NULL,
  `fecha_produccion` date NOT NULL,
  `fecha_vencimiento` date NOT NULL,
  `cantidad_producida` int(11) NOT NULL,
  `estado_calidad` enum('Pendiente','Aprobado','Rechazado') DEFAULT 'Pendiente',
  `tecnico_responsable` varchar(100) DEFAULT NULL,
  `observaciones_calidad` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `lotes`
--

INSERT INTO `lotes` (`id_lote`, `numero_lote_unico`, `id_presentacion`, `id_planta_origen`, `fecha_produccion`, `fecha_vencimiento`, `cantidad_producida`, `estado_calidad`, `tecnico_responsable`, `observaciones_calidad`) VALUES
(1, 'LOTE-PAC-001', 2, 1, '2026-01-10', '2026-04-10', 5000, 'Aprobado', 'Ing. Nestor Quispe', 'Lote liberado sin observaciones técnicas.'),
(2, 'LOTE-HUA-002', 4, 2, '2026-05-15', '2026-06-20', 3000, 'Aprobado', 'Ing. Rocio Mamani', 'Control de densidad y amargor correcto. Vence pronto.'),
(3, 'LOTE-TAQ-003', 5, 3, '2026-06-01', '2026-12-01', 4000, 'Pendiente', 'Ing. Hugo Villca', 'En proceso de incubación microbiológica.');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `movimientos_inventario`
--

CREATE TABLE `movimientos_inventario` (
  `id_movimiento` int(11) NOT NULL,
  `id_bodega_origen` int(11) DEFAULT NULL,
  `id_bodega_destino` int(11) DEFAULT NULL,
  `id_presentacion` int(11) NOT NULL,
  `id_lote` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `tipo_movimiento` enum('Entrada por Produccion','Salida por Venta','Traslado entre Bodegas') NOT NULL,
  `cantidad` int(11) NOT NULL,
  `fecha_movimiento` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `movimientos_inventario`
--

INSERT INTO `movimientos_inventario` (`id_movimiento`, `id_bodega_origen`, `id_bodega_destino`, `id_presentacion`, `id_lote`, `id_usuario`, `tipo_movimiento`, `cantidad`, `fecha_movimiento`) VALUES
(1, NULL, 1, 2, 1, 1, 'Entrada por Produccion', 5000, '2026-06-05 16:49:22'),
(2, NULL, 4, 4, 2, 2, 'Entrada por Produccion', 3000, '2026-06-05 16:49:22'),
(3, NULL, 7, 5, 3, 2, 'Entrada por Produccion', 4000, '2026-06-05 16:49:22'),
(4, 1, NULL, 2, 1, 1, 'Salida por Venta', 500, '2026-06-05 16:54:28');

--
-- Disparadores `movimientos_inventario`
--
DELIMITER $$
CREATE TRIGGER `tr_control_stock_automatico` AFTER INSERT ON `movimientos_inventario` FOR EACH ROW BEGIN
    IF NEW.tipo_movimiento = 'Entrada por Produccion' THEN
        INSERT INTO inventario_bodega (id_bodega, id_presentacion, id_lote, stock_actual)
        VALUES (NEW.id_bodega_destino, NEW.id_presentacion, NEW.id_lote, NEW.cantidad)
        ON DUPLICATE KEY UPDATE stock_actual = stock_actual + NEW.cantidad;

    ELSEIF NEW.tipo_movimiento = 'Salida por Venta' THEN
        UPDATE inventario_bodega 
        SET stock_actual = stock_actual - NEW.cantidad
        WHERE id_bodega = NEW.id_bodega_origen 
          AND id_presentacion = NEW.id_presentacion 
          AND id_lote = NEW.id_lote;

    ELSEIF NEW.tipo_movimiento = 'Traslado entre Bodegas' THEN

        UPDATE inventario_bodega 
        SET stock_actual = stock_actual - NEW.cantidad
        WHERE id_bodega = NEW.id_bodega_origen 
          AND id_presentacion = NEW.id_presentacion 
          AND id_lote = NEW.id_lote;

        INSERT INTO inventario_bodega (id_bodega, id_presentacion, id_lote, stock_actual)
        VALUES (NEW.id_bodega_destino, NEW.id_presentacion, NEW.id_lote, NEW.cantidad)
        ON DUPLICATE KEY UPDATE stock_actual = stock_actual + NEW.cantidad;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pedidos`
--

CREATE TABLE `pedidos` (
  `id_pedido` int(11) NOT NULL,
  `id_distribuidor` int(11) NOT NULL,
  `fecha_pedido` datetime DEFAULT current_timestamp(),
  `fecha_entrega_requerida` date NOT NULL,
  `estado_pedido` enum('Pendiente','Despachado','Entregado','Cancelado') DEFAULT 'Pendiente'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `pedidos`
--

INSERT INTO `pedidos` (`id_pedido`, `id_distribuidor`, `fecha_pedido`, `fecha_entrega_requerida`, `estado_pedido`) VALUES
(1, 1, '2026-06-05 11:49:22', '2026-06-10', 'Pendiente');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `plantas`
--

CREATE TABLE `plantas` (
  `id_planta` int(11) NOT NULL,
  `nombre_planta` varchar(100) NOT NULL,
  `ubicacion_especifica` varchar(150) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `plantas`
--

INSERT INTO `plantas` (`id_planta`, `nombre_planta`, `ubicacion_especifica`) VALUES
(1, 'La Paz', 'Mecapaca'),
(2, 'Cochabamba', 'Sacaba'),
(3, 'Santa Cruz', 'Palmasola');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `presentaciones`
--

CREATE TABLE `presentaciones` (
  `id_presentacion` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL,
  `codigo_presentacion` varchar(30) NOT NULL,
  `empaque` varchar(50) NOT NULL,
  `volumen` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `presentaciones`
--

INSERT INTO `presentaciones` (`id_presentacion`, `id_producto`, `codigo_presentacion`, `empaque`, `volumen`) VALUES
(1, 1, 'PAC-355', 'Botella vidrio', '355ml'),
(2, 1, 'PAC-620', 'Botella vidrio', '620ml'),
(3, 1, 'PAC-1L', 'Botella vidrio', '1L'),
(4, 2, 'HUA-620', 'Botella vidrio', '620ml'),
(5, 3, 'TAQ-620', 'Botella vidrio', '620ml');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

CREATE TABLE `productos` (
  `id_producto` int(11) NOT NULL,
  `codigo_unico` varchar(30) NOT NULL,
  `nombre_comercial` varchar(100) NOT NULL,
  `tipo_cerveza` varchar(50) NOT NULL,
  `graduacion_alcoholica` decimal(4,1) NOT NULL,
  `precio_actual` decimal(10,2) NOT NULL,
  `stock_minimo_alerta` int(11) NOT NULL DEFAULT 100,
  `stock_maximo_alerta` int(11) NOT NULL DEFAULT 5000
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `productos`
--

INSERT INTO `productos` (`id_producto`, `codigo_unico`, `nombre_comercial`, `tipo_cerveza`, `graduacion_alcoholica`, `precio_actual`, `stock_minimo_alerta`, `stock_maximo_alerta`) VALUES
(1, 'PROD-PAC', 'Paceña', 'Pilsener', 4.8, 12.00, 200, 10000),
(2, 'PROD-HUA', 'Huari', 'Lager', 5.0, 15.00, 150, 7000),
(3, 'PROD-TAQ', 'Taquiña', 'Pilsener', 4.5, 11.00, 100, 5000);

--
-- Disparadores `productos`
--
DELIMITER $$
CREATE TRIGGER `tr_auditoria_precios_productos` AFTER UPDATE ON `productos` FOR EACH ROW BEGIN
    -- Solo disparamos el log si el precio realmente cambió
    IF OLD.precio_actual <> NEW.precio_actual THEN
        INSERT INTO logs_auditoria (
            tabla_afectada, 
            accion_realizada, 
            id_registro_afectado, 
            valores_anteriores, 
            valores_nuevos, 
            usuario_bd
        )
        VALUES (
            'productos',
            'UPDATE',
            OLD.id_producto,
            CONCAT('Nombre: ', OLD.nombre_comercial, ' | Precio Viejo: ', OLD.precio_actual),
            CONCAT('Nombre: ', NEW.nombre_comercial, ' | Precio Nuevo: ', NEW.precio_actual),
            USER() -- Captura la cuenta de MySQL conectada (ej: root@localhost)
        );
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `roles`
--

CREATE TABLE `roles` (
  `id_rol` int(11) NOT NULL,
  `nombre_rol` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `roles`
--

INSERT INTO `roles` (`id_rol`, `nombre_rol`) VALUES
(1, 'Administrador'),
(3, 'Distribuidor'),
(2, 'Gerente');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id_usuario` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `nombre_completo` varchar(100) NOT NULL,
  `correo` varchar(100) NOT NULL,
  `id_rol` int(11) NOT NULL,
  `activo` tinyint(1) DEFAULT 1,
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id_usuario`, `username`, `password_hash`, `nombre_completo`, `correo`, `id_rol`, `activo`, `fecha_creacion`) VALUES
(1, 'admin_pil', 'scrypt:32768:8:1$u7Xn8YmWp3qR9sTv$ee88cd3b0bfbc560bc13560706bf807b520c15926639c0f0559f9ef7bc036a11', 'Super Administrador PIL', 'admin@pilandina.bo', 1, 1, '2026-06-05 16:44:23'),
(2, 'carlos_gerente', 'scrypt:32768:8:1$v8Yo9ZnXq4rS0uUw$ad14f9d26be7dcb8b2f913d801bf405c110a24128036c0a0448e8ef6bc014b22', 'Ing. Carlos Mendoza', 'carlos.mendoza@pilandina.bo', 2, 1, '2026-06-05 16:44:23'),
(3, 'maria_control', 'scrypt:32768:8:1$v8Yo9ZnXq4rS0uUw$ad14f9d26be7dcb8b2f913d801bf405c110a24128036c0a0448e8ef6bc014b22', 'Lic. María Choque', 'maria.choque@pilandina.bo', 2, 1, '2026-06-05 16:44:23'),
(4, 'dist_tiendas_bolivia', 'scrypt:32768:8:1$w9Zp0AoYr5sT1vVx$bd25f0e37cf8edc9c3fa24e902cf506d220b35139047d0b0559f9fa7cd025c33', 'Distribuidora Tiendas Bolivia S.A.', 'pedidos@tiendasbolivia.com.bo', 3, 1, '2026-06-05 16:44:23'),
(5, 'dist_norte_lp', 'scrypt:32768:8:1$w9Zp0AoYr5sT1vVx$bd25f0e37cf8edc9c3fa24e902cf506d220b35139047d0b0559f9fa7cd025c33', 'Comercializadora Norte La Paz', 'contacto@comercialnorte.com', 3, 1, '2026-06-05 16:44:23');

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_alertas_vencimiento`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_alertas_vencimiento` (
`Numero_Lote` varchar(50)
,`Producto` varchar(100)
,`Presentacion` varchar(20)
,`Planta_Origen` varchar(100)
,`Fecha_Vencimiento` date
,`Dias_Restantes` int(7)
,`Stock_En_Riesgo` decimal(32,0)
,`Nivel_Urgencia` varchar(42)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_pedidos_pendientes`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_pedidos_pendientes` (
`Nro_Pedido` int(11)
,`Distribuidor` varchar(150)
,`Ciudad_Destino` varchar(50)
,`Fecha_Solicitud` datetime
,`Fecha_Entrega_Pactada` date
,`Factura_Asociada` varchar(50)
,`Importe_Bs` decimal(10,2)
,`Estado_Pago` enum('Pendiente','Pagado','Anulado')
,`Estado_Despacho` enum('Pendiente','Despachado','Entregado','Cancelado')
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_stock_consolidado`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_stock_consolidado` (
`Producto` varchar(100)
,`Presentacion` varchar(20)
,`Empaque` varchar(50)
,`Planta` varchar(100)
,`Bodega` varchar(100)
,`Total_Disponible` decimal(32,0)
,`Stock_Minimo_Configurado` int(11)
,`Estado_Inventario` varchar(21)
);

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_alertas_vencimiento`
--
DROP TABLE IF EXISTS `vista_alertas_vencimiento`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_alertas_vencimiento`  AS SELECT `l`.`numero_lote_unico` AS `Numero_Lote`, `p`.`nombre_comercial` AS `Producto`, `pres`.`volumen` AS `Presentacion`, `pl`.`nombre_planta` AS `Planta_Origen`, `l`.`fecha_vencimiento` AS `Fecha_Vencimiento`, to_days(`l`.`fecha_vencimiento`) - to_days(curdate()) AS `Dias_Restantes`, sum(`ib`.`stock_actual`) AS `Stock_En_Riesgo`, CASE WHEN to_days(`l`.`fecha_vencimiento`) - to_days(curdate()) <= 0 THEN 'PRODUCTO VENCIDO' WHEN to_days(`l`.`fecha_vencimiento`) - to_days(curdate()) <= 7 THEN 'ALERTA ROJA: Vence en menos de 7 dias' WHEN to_days(`l`.`fecha_vencimiento`) - to_days(curdate()) <= 15 THEN 'ALERTA AMARILLA: Vence en menos de 15 dias' ELSE 'ALERTA VERDE: Vence en menos de 30 dias' END AS `Nivel_Urgencia` FROM ((((`lotes` `l` join `presentaciones` `pres` on(`l`.`id_presentacion` = `pres`.`id_presentacion`)) join `productos` `p` on(`pres`.`id_producto` = `p`.`id_producto`)) join `plantas` `pl` on(`l`.`id_planta_origen` = `pl`.`id_planta`)) left join `inventario_bodega` `ib` on(`l`.`id_lote` = `ib`.`id_lote`)) WHERE `l`.`fecha_vencimiento` <= curdate() + interval 30 day GROUP BY `l`.`id_lote` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_pedidos_pendientes`
--
DROP TABLE IF EXISTS `vista_pedidos_pendientes`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_pedidos_pendientes`  AS SELECT `pe`.`id_pedido` AS `Nro_Pedido`, `d`.`razon_social` AS `Distribuidor`, `d`.`ciudad` AS `Ciudad_Destino`, `pe`.`fecha_pedido` AS `Fecha_Solicitud`, `pe`.`fecha_entrega_requerida` AS `Fecha_Entrega_Pactada`, `f`.`nro_factura` AS `Factura_Asociada`, `f`.`monto_total` AS `Importe_Bs`, `f`.`estado_pago` AS `Estado_Pago`, `pe`.`estado_pedido` AS `Estado_Despacho` FROM ((`pedidos` `pe` join `distribuidores` `d` on(`pe`.`id_distribuidor` = `d`.`id_distribuidor`)) left join `facturas` `f` on(`pe`.`id_pedido` = `f`.`id_pedido`)) WHERE `pe`.`estado_pedido` in ('Pendiente','Despachado') ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_stock_consolidado`
--
DROP TABLE IF EXISTS `vista_stock_consolidado`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_stock_consolidado`  AS SELECT `p`.`nombre_comercial` AS `Producto`, `pres`.`volumen` AS `Presentacion`, `pres`.`empaque` AS `Empaque`, `pl`.`nombre_planta` AS `Planta`, `b`.`nombre_bodega` AS `Bodega`, sum(`ib`.`stock_actual`) AS `Total_Disponible`, `p`.`stock_minimo_alerta` AS `Stock_Minimo_Configurado`, CASE WHEN sum(`ib`.`stock_actual`) <= `p`.`stock_minimo_alerta` THEN 'ALERTA: STOCK CRÍTICO' WHEN sum(`ib`.`stock_actual`) >= `p`.`stock_maximo_alerta` THEN 'ALERTA: SOBRE-STOCK' ELSE 'Normal' END AS `Estado_Inventario` FROM ((((`inventario_bodega` `ib` join `presentaciones` `pres` on(`ib`.`id_presentacion` = `pres`.`id_presentacion`)) join `productos` `p` on(`pres`.`id_producto` = `p`.`id_producto`)) join `bodegas` `b` on(`ib`.`id_bodega` = `b`.`id_bodega`)) join `plantas` `pl` on(`b`.`id_planta` = `pl`.`id_planta`)) GROUP BY `p`.`id_producto`, `pres`.`id_presentacion`, `pl`.`id_planta`, `b`.`id_bodega` ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `bodegas`
--
ALTER TABLE `bodegas`
  ADD PRIMARY KEY (`id_bodega`),
  ADD KEY `id_planta` (`id_planta`);

--
-- Indices de la tabla `detalle_pedidos`
--
ALTER TABLE `detalle_pedidos`
  ADD PRIMARY KEY (`id_detalle`),
  ADD KEY `id_pedido` (`id_pedido`),
  ADD KEY `id_presentacion` (`id_presentacion`);

--
-- Indices de la tabla `distribuidores`
--
ALTER TABLE `distribuidores`
  ADD PRIMARY KEY (`id_distribuidor`),
  ADD UNIQUE KEY `nit` (`nit`),
  ADD UNIQUE KEY `correo` (`correo`);

--
-- Indices de la tabla `facturas`
--
ALTER TABLE `facturas`
  ADD PRIMARY KEY (`id_factura`),
  ADD UNIQUE KEY `id_pedido` (`id_pedido`),
  ADD UNIQUE KEY `nro_factura` (`nro_factura`);

--
-- Indices de la tabla `inventario_bodega`
--
ALTER TABLE `inventario_bodega`
  ADD PRIMARY KEY (`id_inventario`),
  ADD UNIQUE KEY `uq_bodega_presentacion_lote` (`id_bodega`,`id_presentacion`,`id_lote`),
  ADD KEY `id_presentacion` (`id_presentacion`),
  ADD KEY `id_lote` (`id_lote`);

--
-- Indices de la tabla `logs_auditoria`
--
ALTER TABLE `logs_auditoria`
  ADD PRIMARY KEY (`id_log`);

--
-- Indices de la tabla `lotes`
--
ALTER TABLE `lotes`
  ADD PRIMARY KEY (`id_lote`),
  ADD UNIQUE KEY `numero_lote_unico` (`numero_lote_unico`),
  ADD KEY `id_presentacion` (`id_presentacion`),
  ADD KEY `id_planta_origen` (`id_planta_origen`),
  ADD KEY `idx_lotes_fecha_vencimiento` (`fecha_vencimiento`);

--
-- Indices de la tabla `movimientos_inventario`
--
ALTER TABLE `movimientos_inventario`
  ADD PRIMARY KEY (`id_movimiento`),
  ADD KEY `id_bodega_origen` (`id_bodega_origen`),
  ADD KEY `id_bodega_destino` (`id_bodega_destino`),
  ADD KEY `id_presentacion` (`id_presentacion`),
  ADD KEY `id_lote` (`id_lote`),
  ADD KEY `id_usuario` (`id_usuario`),
  ADD KEY `idx_movimientos_tipo` (`tipo_movimiento`);

--
-- Indices de la tabla `pedidos`
--
ALTER TABLE `pedidos`
  ADD PRIMARY KEY (`id_pedido`),
  ADD KEY `id_distribuidor` (`id_distribuidor`),
  ADD KEY `idx_pedidos_estado` (`estado_pedido`);

--
-- Indices de la tabla `plantas`
--
ALTER TABLE `plantas`
  ADD PRIMARY KEY (`id_planta`);

--
-- Indices de la tabla `presentaciones`
--
ALTER TABLE `presentaciones`
  ADD PRIMARY KEY (`id_presentacion`),
  ADD UNIQUE KEY `codigo_presentacion` (`codigo_presentacion`),
  ADD KEY `id_producto` (`id_producto`);

--
-- Indices de la tabla `productos`
--
ALTER TABLE `productos`
  ADD PRIMARY KEY (`id_producto`),
  ADD UNIQUE KEY `codigo_unico` (`codigo_unico`);

--
-- Indices de la tabla `roles`
--
ALTER TABLE `roles`
  ADD PRIMARY KEY (`id_rol`),
  ADD UNIQUE KEY `nombre_rol` (`nombre_rol`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id_usuario`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `correo` (`correo`),
  ADD KEY `id_rol` (`id_rol`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `bodegas`
--
ALTER TABLE `bodegas`
  MODIFY `id_bodega` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT de la tabla `detalle_pedidos`
--
ALTER TABLE `detalle_pedidos`
  MODIFY `id_detalle` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `distribuidores`
--
ALTER TABLE `distribuidores`
  MODIFY `id_distribuidor` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `facturas`
--
ALTER TABLE `facturas`
  MODIFY `id_factura` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `inventario_bodega`
--
ALTER TABLE `inventario_bodega`
  MODIFY `id_inventario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `logs_auditoria`
--
ALTER TABLE `logs_auditoria`
  MODIFY `id_log` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `lotes`
--
ALTER TABLE `lotes`
  MODIFY `id_lote` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `movimientos_inventario`
--
ALTER TABLE `movimientos_inventario`
  MODIFY `id_movimiento` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `pedidos`
--
ALTER TABLE `pedidos`
  MODIFY `id_pedido` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `plantas`
--
ALTER TABLE `plantas`
  MODIFY `id_planta` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `presentaciones`
--
ALTER TABLE `presentaciones`
  MODIFY `id_presentacion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `productos`
--
ALTER TABLE `productos`
  MODIFY `id_producto` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `roles`
--
ALTER TABLE `roles`
  MODIFY `id_rol` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id_usuario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `bodegas`
--
ALTER TABLE `bodegas`
  ADD CONSTRAINT `bodegas_ibfk_1` FOREIGN KEY (`id_planta`) REFERENCES `plantas` (`id_planta`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `detalle_pedidos`
--
ALTER TABLE `detalle_pedidos`
  ADD CONSTRAINT `detalle_pedidos_ibfk_1` FOREIGN KEY (`id_pedido`) REFERENCES `pedidos` (`id_pedido`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `detalle_pedidos_ibfk_2` FOREIGN KEY (`id_presentacion`) REFERENCES `presentaciones` (`id_presentacion`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `facturas`
--
ALTER TABLE `facturas`
  ADD CONSTRAINT `facturas_ibfk_1` FOREIGN KEY (`id_pedido`) REFERENCES `pedidos` (`id_pedido`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `inventario_bodega`
--
ALTER TABLE `inventario_bodega`
  ADD CONSTRAINT `inventario_bodega_ibfk_1` FOREIGN KEY (`id_bodega`) REFERENCES `bodegas` (`id_bodega`) ON UPDATE CASCADE,
  ADD CONSTRAINT `inventario_bodega_ibfk_2` FOREIGN KEY (`id_presentacion`) REFERENCES `presentaciones` (`id_presentacion`) ON UPDATE CASCADE,
  ADD CONSTRAINT `inventario_bodega_ibfk_3` FOREIGN KEY (`id_lote`) REFERENCES `lotes` (`id_lote`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `lotes`
--
ALTER TABLE `lotes`
  ADD CONSTRAINT `lotes_ibfk_1` FOREIGN KEY (`id_presentacion`) REFERENCES `presentaciones` (`id_presentacion`) ON UPDATE CASCADE,
  ADD CONSTRAINT `lotes_ibfk_2` FOREIGN KEY (`id_planta_origen`) REFERENCES `plantas` (`id_planta`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `movimientos_inventario`
--
ALTER TABLE `movimientos_inventario`
  ADD CONSTRAINT `movimientos_inventario_ibfk_1` FOREIGN KEY (`id_bodega_origen`) REFERENCES `bodegas` (`id_bodega`) ON UPDATE CASCADE,
  ADD CONSTRAINT `movimientos_inventario_ibfk_2` FOREIGN KEY (`id_bodega_destino`) REFERENCES `bodegas` (`id_bodega`) ON UPDATE CASCADE,
  ADD CONSTRAINT `movimientos_inventario_ibfk_3` FOREIGN KEY (`id_presentacion`) REFERENCES `presentaciones` (`id_presentacion`) ON UPDATE CASCADE,
  ADD CONSTRAINT `movimientos_inventario_ibfk_4` FOREIGN KEY (`id_lote`) REFERENCES `lotes` (`id_lote`) ON UPDATE CASCADE,
  ADD CONSTRAINT `movimientos_inventario_ibfk_5` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `pedidos`
--
ALTER TABLE `pedidos`
  ADD CONSTRAINT `pedidos_ibfk_1` FOREIGN KEY (`id_distribuidor`) REFERENCES `distribuidores` (`id_distribuidor`) ON UPDATE CASCADE;

--
-- Filtros para la tabla `presentaciones`
--
ALTER TABLE `presentaciones`
  ADD CONSTRAINT `presentaciones_ibfk_1` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Filtros para la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD CONSTRAINT `usuarios_ibfk_1` FOREIGN KEY (`id_rol`) REFERENCES `roles` (`id_rol`) ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
