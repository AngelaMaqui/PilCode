-- PIL Andina - Esquema de base de datos
-- Generado automáticamente desde la BD activa
CREATE DATABASE IF NOT EXISTS `pil_andina`;
USE `pil_andina`;

DROP TABLE IF EXISTS `bodegas`;
CREATE TABLE `bodegas` (
  `id_bodega` int(11) NOT NULL AUTO_INCREMENT,
  `id_planta` int(11) NOT NULL,
  `nombre_bodega` varchar(100) NOT NULL,
  `capacidad_maxima` int(11) NOT NULL,
  `temperatura_almacenamiento` decimal(4,2) NOT NULL,
  PRIMARY KEY (`id_bodega`),
  KEY `id_planta` (`id_planta`),
  CONSTRAINT `bodegas_ibfk_1` FOREIGN KEY (`id_planta`) REFERENCES `plantas` (`id_planta`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

DROP TABLE IF EXISTS `detalle_pedidos`;
CREATE TABLE `detalle_pedidos` (
  `id_detalle` int(11) NOT NULL AUTO_INCREMENT,
  `id_pedido` int(11) NOT NULL,
  `id_presentacion` int(11) NOT NULL,
  `cantidad_solicitada` int(11) NOT NULL,
  `precio_unitario_historico` decimal(10,2) NOT NULL,
  PRIMARY KEY (`id_detalle`),
  KEY `id_pedido` (`id_pedido`),
  KEY `id_presentacion` (`id_presentacion`),
  CONSTRAINT `detalle_pedidos_ibfk_1` FOREIGN KEY (`id_pedido`) REFERENCES `pedidos` (`id_pedido`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `detalle_pedidos_ibfk_2` FOREIGN KEY (`id_presentacion`) REFERENCES `presentaciones` (`id_presentacion`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

DROP TABLE IF EXISTS `distribuidores`;
CREATE TABLE `distribuidores` (
  `id_distribuidor` int(11) NOT NULL AUTO_INCREMENT,
  `nit` varchar(30) NOT NULL,
  `razon_social` varchar(150) NOT NULL,
  `direccion` varchar(255) NOT NULL,
  `ciudad` varchar(50) NOT NULL,
  `zona` varchar(100) NOT NULL,
  `contacto_nombre` varchar(100) NOT NULL,
  `telefono` varchar(30) NOT NULL,
  `correo` varchar(100) NOT NULL,
  PRIMARY KEY (`id_distribuidor`),
  UNIQUE KEY `nit` (`nit`),
  UNIQUE KEY `correo` (`correo`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

DROP TABLE IF EXISTS `facturas`;
CREATE TABLE `facturas` (
  `id_factura` int(11) NOT NULL AUTO_INCREMENT,
  `id_pedido` int(11) NOT NULL,
  `nro_factura` varchar(50) NOT NULL,
  `monto_total` decimal(10,2) NOT NULL,
  `estado_pago` enum('Pendiente','Pagado','Anulado') DEFAULT 'Pendiente',
  `fecha_emision` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_factura`),
  UNIQUE KEY `id_pedido` (`id_pedido`),
  UNIQUE KEY `nro_factura` (`nro_factura`),
  CONSTRAINT `facturas_ibfk_1` FOREIGN KEY (`id_pedido`) REFERENCES `pedidos` (`id_pedido`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

DROP TABLE IF EXISTS `inventario_bodega`;
CREATE TABLE `inventario_bodega` (
  `id_inventario` int(11) NOT NULL AUTO_INCREMENT,
  `id_bodega` int(11) NOT NULL,
  `id_presentacion` int(11) NOT NULL,
  `id_lote` int(11) NOT NULL,
  `stock_actual` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id_inventario`),
  UNIQUE KEY `uq_bodega_presentacion_lote` (`id_bodega`,`id_presentacion`,`id_lote`),
  KEY `id_presentacion` (`id_presentacion`),
  KEY `id_lote` (`id_lote`),
  CONSTRAINT `inventario_bodega_ibfk_1` FOREIGN KEY (`id_bodega`) REFERENCES `bodegas` (`id_bodega`) ON UPDATE CASCADE,
  CONSTRAINT `inventario_bodega_ibfk_2` FOREIGN KEY (`id_presentacion`) REFERENCES `presentaciones` (`id_presentacion`) ON UPDATE CASCADE,
  CONSTRAINT `inventario_bodega_ibfk_3` FOREIGN KEY (`id_lote`) REFERENCES `lotes` (`id_lote`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

DROP TABLE IF EXISTS `logs_auditoria`;
CREATE TABLE `logs_auditoria` (
  `id_log` int(11) NOT NULL AUTO_INCREMENT,
  `tabla_afectada` varchar(50) NOT NULL,
  `accion_realizada` enum('INSERT','UPDATE','DELETE') NOT NULL,
  `id_registro_afectado` int(11) NOT NULL,
  `valores_anteriores` text DEFAULT NULL,
  `valores_nuevos` text DEFAULT NULL,
  `usuario_bd` varchar(50) NOT NULL,
  `fecha_accion` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_log`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

DROP TABLE IF EXISTS `lotes`;
CREATE TABLE `lotes` (
  `id_lote` int(11) NOT NULL AUTO_INCREMENT,
  `numero_lote_unico` varchar(50) NOT NULL,
  `id_presentacion` int(11) NOT NULL,
  `id_planta_origen` int(11) NOT NULL,
  `fecha_produccion` date NOT NULL,
  `fecha_vencimiento` date NOT NULL,
  `cantidad_producida` int(11) NOT NULL,
  `estado_calidad` enum('Pendiente','Aprobado','Rechazado') DEFAULT 'Pendiente',
  `tecnico_responsable` varchar(100) DEFAULT NULL,
  `observaciones_calidad` text DEFAULT NULL,
  PRIMARY KEY (`id_lote`),
  UNIQUE KEY `numero_lote_unico` (`numero_lote_unico`),
  KEY `id_presentacion` (`id_presentacion`),
  KEY `id_planta_origen` (`id_planta_origen`),
  KEY `idx_lotes_fecha_vencimiento` (`fecha_vencimiento`),
  CONSTRAINT `lotes_ibfk_1` FOREIGN KEY (`id_presentacion`) REFERENCES `presentaciones` (`id_presentacion`) ON UPDATE CASCADE,
  CONSTRAINT `lotes_ibfk_2` FOREIGN KEY (`id_planta_origen`) REFERENCES `plantas` (`id_planta`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

DROP TABLE IF EXISTS `movimientos_inventario`;
CREATE TABLE `movimientos_inventario` (
  `id_movimiento` int(11) NOT NULL AUTO_INCREMENT,
  `id_bodega_origen` int(11) DEFAULT NULL,
  `id_bodega_destino` int(11) DEFAULT NULL,
  `id_presentacion` int(11) NOT NULL,
  `id_lote` int(11) NOT NULL,
  `id_usuario` int(11) NOT NULL,
  `tipo_movimiento` enum('Entrada por Produccion','Salida por Venta','Traslado entre Bodegas') NOT NULL,
  `cantidad` int(11) NOT NULL,
  `fecha_movimiento` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_movimiento`),
  KEY `id_bodega_origen` (`id_bodega_origen`),
  KEY `id_bodega_destino` (`id_bodega_destino`),
  KEY `id_presentacion` (`id_presentacion`),
  KEY `id_lote` (`id_lote`),
  KEY `id_usuario` (`id_usuario`),
  KEY `idx_movimientos_tipo` (`tipo_movimiento`),
  CONSTRAINT `movimientos_inventario_ibfk_1` FOREIGN KEY (`id_bodega_origen`) REFERENCES `bodegas` (`id_bodega`) ON UPDATE CASCADE,
  CONSTRAINT `movimientos_inventario_ibfk_2` FOREIGN KEY (`id_bodega_destino`) REFERENCES `bodegas` (`id_bodega`) ON UPDATE CASCADE,
  CONSTRAINT `movimientos_inventario_ibfk_3` FOREIGN KEY (`id_presentacion`) REFERENCES `presentaciones` (`id_presentacion`) ON UPDATE CASCADE,
  CONSTRAINT `movimientos_inventario_ibfk_4` FOREIGN KEY (`id_lote`) REFERENCES `lotes` (`id_lote`) ON UPDATE CASCADE,
  CONSTRAINT `movimientos_inventario_ibfk_5` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

DROP TABLE IF EXISTS `pedidos`;
CREATE TABLE `pedidos` (
  `id_pedido` int(11) NOT NULL AUTO_INCREMENT,
  `id_distribuidor` int(11) NOT NULL,
  `fecha_pedido` datetime DEFAULT current_timestamp(),
  `fecha_entrega_requerida` date NOT NULL,
  `estado_pedido` enum('Pendiente','Despachado','Entregado','Cancelado') DEFAULT 'Pendiente',
  PRIMARY KEY (`id_pedido`),
  KEY `id_distribuidor` (`id_distribuidor`),
  KEY `idx_pedidos_estado` (`estado_pedido`),
  CONSTRAINT `pedidos_ibfk_1` FOREIGN KEY (`id_distribuidor`) REFERENCES `distribuidores` (`id_distribuidor`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

DROP TABLE IF EXISTS `plantas`;
CREATE TABLE `plantas` (
  `id_planta` int(11) NOT NULL AUTO_INCREMENT,
  `nombre_planta` varchar(100) NOT NULL,
  `ubicacion_especifica` varchar(150) NOT NULL,
  PRIMARY KEY (`id_planta`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

DROP TABLE IF EXISTS `presentaciones`;
CREATE TABLE `presentaciones` (
  `id_presentacion` int(11) NOT NULL AUTO_INCREMENT,
  `id_producto` int(11) NOT NULL,
  `codigo_presentacion` varchar(30) NOT NULL,
  `empaque` varchar(50) NOT NULL,
  `volumen` varchar(20) NOT NULL,
  PRIMARY KEY (`id_presentacion`),
  UNIQUE KEY `codigo_presentacion` (`codigo_presentacion`),
  KEY `id_producto` (`id_producto`),
  CONSTRAINT `presentaciones_ibfk_1` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

DROP TABLE IF EXISTS `productos`;
CREATE TABLE `productos` (
  `id_producto` int(11) NOT NULL AUTO_INCREMENT,
  `codigo_unico` varchar(30) NOT NULL,
  `nombre_comercial` varchar(100) NOT NULL,
  `tipo_cerveza` varchar(50) NOT NULL,
  `graduacion_alcoholica` decimal(4,1) NOT NULL,
  `precio_actual` decimal(10,2) NOT NULL,
  `stock_minimo_alerta` int(11) NOT NULL DEFAULT 100,
  `stock_maximo_alerta` int(11) NOT NULL DEFAULT 5000,
  PRIMARY KEY (`id_producto`),
  UNIQUE KEY `codigo_unico` (`codigo_unico`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

DROP TABLE IF EXISTS `roles`;
CREATE TABLE `roles` (
  `id_rol` int(11) NOT NULL AUTO_INCREMENT,
  `nombre_rol` varchar(50) NOT NULL,
  PRIMARY KEY (`id_rol`),
  UNIQUE KEY `nombre_rol` (`nombre_rol`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

DROP TABLE IF EXISTS `usuarios`;
CREATE TABLE `usuarios` (
  `id_usuario` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `nombre_completo` varchar(100) NOT NULL,
  `correo` varchar(100) NOT NULL,
  `id_rol` int(11) NOT NULL,
  `activo` tinyint(1) DEFAULT 1,
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id_usuario`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `correo` (`correo`),
  KEY `id_rol` (`id_rol`),
  CONSTRAINT `usuarios_ibfk_1` FOREIGN KEY (`id_rol`) REFERENCES `roles` (`id_rol`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

DROP VIEW IF EXISTS `vista_alertas_vencimiento`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_alertas_vencimiento` AS select `l`.`numero_lote_unico` AS `Numero_Lote`,`p`.`nombre_comercial` AS `Producto`,`pres`.`volumen` AS `Presentacion`,`pl`.`nombre_planta` AS `Planta_Origen`,`l`.`fecha_vencimiento` AS `Fecha_Vencimiento`,to_days(`l`.`fecha_vencimiento`) - to_days(curdate()) AS `Dias_Restantes`,sum(`ib`.`stock_actual`) AS `Stock_En_Riesgo`,case when to_days(`l`.`fecha_vencimiento`) - to_days(curdate()) <= 0 then 'PRODUCTO VENCIDO' when to_days(`l`.`fecha_vencimiento`) - to_days(curdate()) <= 7 then 'ALERTA ROJA: Vence en menos de 7 dias' when to_days(`l`.`fecha_vencimiento`) - to_days(curdate()) <= 15 then 'ALERTA AMARILLA: Vence en menos de 15 dias' else 'ALERTA VERDE: Vence en menos de 30 dias' end AS `Nivel_Urgencia` from ((((`lotes` `l` join `presentaciones` `pres` on(`l`.`id_presentacion` = `pres`.`id_presentacion`)) join `productos` `p` on(`pres`.`id_producto` = `p`.`id_producto`)) join `plantas` `pl` on(`l`.`id_planta_origen` = `pl`.`id_planta`)) left join `inventario_bodega` `ib` on(`l`.`id_lote` = `ib`.`id_lote`)) where `l`.`fecha_vencimiento` <= curdate() + interval 30 day group by `l`.`id_lote`;

DROP VIEW IF EXISTS `vista_pedidos_pendientes`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_pedidos_pendientes` AS select `pe`.`id_pedido` AS `Nro_Pedido`,`d`.`razon_social` AS `Distribuidor`,`d`.`ciudad` AS `Ciudad_Destino`,`pe`.`fecha_pedido` AS `Fecha_Solicitud`,`pe`.`fecha_entrega_requerida` AS `Fecha_Entrega_Pactada`,`f`.`nro_factura` AS `Factura_Asociada`,`f`.`monto_total` AS `Importe_Bs`,`f`.`estado_pago` AS `Estado_Pago`,`pe`.`estado_pedido` AS `Estado_Despacho` from ((`pedidos` `pe` join `distribuidores` `d` on(`pe`.`id_distribuidor` = `d`.`id_distribuidor`)) left join `facturas` `f` on(`pe`.`id_pedido` = `f`.`id_pedido`)) where `pe`.`estado_pedido` in ('Pendiente','Despachado');

DROP VIEW IF EXISTS `vista_stock_consolidado`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_stock_consolidado` AS select `p`.`nombre_comercial` AS `Producto`,`pres`.`volumen` AS `Presentacion`,`pres`.`empaque` AS `Empaque`,`pl`.`nombre_planta` AS `Planta`,`b`.`nombre_bodega` AS `Bodega`,sum(`ib`.`stock_actual`) AS `Total_Disponible`,`p`.`stock_minimo_alerta` AS `Stock_Minimo_Configurado`,case when sum(`ib`.`stock_actual`) <= `p`.`stock_minimo_alerta` then 'ALERTA: STOCK CRÍTICO' when sum(`ib`.`stock_actual`) >= `p`.`stock_maximo_alerta` then 'ALERTA: SOBRE-STOCK' else 'Normal' end AS `Estado_Inventario` from ((((`inventario_bodega` `ib` join `presentaciones` `pres` on(`ib`.`id_presentacion` = `pres`.`id_presentacion`)) join `productos` `p` on(`pres`.`id_producto` = `p`.`id_producto`)) join `bodegas` `b` on(`ib`.`id_bodega` = `b`.`id_bodega`)) join `plantas` `pl` on(`b`.`id_planta` = `pl`.`id_planta`)) group by `p`.`id_producto`,`pres`.`id_presentacion`,`pl`.`id_planta`,`b`.`id_bodega`;

DROP PROCEDURE IF EXISTS `sp_despachar_pedido`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_despachar_pedido`(IN `p_id_pedido` INT, IN `p_id_bodega_origen` INT, IN `p_id_lote_despacho` INT, IN `p_id_usuario` INT)
BEGIN

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
END;;
DELIMITER ;

DROP PROCEDURE IF EXISTS `sp_registrar_produccion_lote`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_produccion_lote`(IN `p_numero_lote` VARCHAR(50), IN `p_id_presentacion` INT, IN `p_id_planta` INT, IN `p_id_bodega` INT, IN `p_fecha_prod` DATE, IN `p_fecha_venc` DATE, IN `p_cantidad` INT, IN `p_tecnico` VARCHAR(100), IN `p_id_usuario` INT)
BEGIN

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
END;;
DELIMITER ;

DROP TRIGGER IF EXISTS `tr_control_stock_automatico`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` TRIGGER `tr_control_stock_automatico` AFTER INSERT ON `movimientos_inventario` FOR EACH ROW BEGIN
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
END;;
DELIMITER ;

DROP TRIGGER IF EXISTS `tr_auditoria_precios_productos`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` TRIGGER `tr_auditoria_precios_productos` AFTER UPDATE ON `productos` FOR EACH ROW BEGIN
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
END;;
DELIMITER ;
