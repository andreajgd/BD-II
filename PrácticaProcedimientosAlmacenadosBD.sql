CREATE DATABASE FarmalinkDB;
GO

USE FarmalinkDB;
GO

--creación tablas
CREATE TABLE Medicamento (
    CodigoMedicamento INT PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Precio DECIMAL(10,2) NOT NULL
);

CREATE TABLE Bodega (
    CodigoBodega INT PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Ubicacion VARCHAR(150) NOT NULL
);

CREATE TABLE Cliente (
    CodigoCliente INT PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Telefono VARCHAR(20)
);

CREATE TABLE Inventario (
    CodigoMedicamento INT NOT NULL,
    CodigoBodega INT NOT NULL,
    Stock INT NOT NULL,
    StockMinimo INT NOT NULL,

    PRIMARY KEY (CodigoMedicamento, CodigoBodega),

    FOREIGN KEY (CodigoMedicamento)
        REFERENCES Medicamento(CodigoMedicamento),

    FOREIGN KEY (CodigoBodega)
        REFERENCES Bodega(CodigoBodega),

    CHECK (Stock >= 0),
    CHECK (StockMinimo >= 0)
);

CREATE TABLE Pedido (
    CodigoPedido INT PRIMARY KEY,
    CodigoCliente INT NOT NULL,
    FechaPedido DATE NOT NULL,
    Estado VARCHAR(20) NOT NULL,
    Total DECIMAL(10,2) NOT NULL,

    FOREIGN KEY (CodigoCliente)
        REFERENCES Cliente(CodigoCliente),

    CHECK (Estado IN ('Pendiente', 'Entregado', 'Cancelado'))
);

--insercción de datos
INSERT INTO Medicamento VALUES
(1, 'Acetaminofén 500mg', 25.00),
(2, 'Ibuprofeno 400mg', 35.00),
(3, 'Amoxicilina 500mg', 80.00);

INSERT INTO Bodega VALUES
(1, 'Bodega Managua', 'Managua'),
(2, 'Bodega León', 'León'),
(3, 'Bodega Granada', 'Granada');

INSERT INTO Cliente VALUES
(1, 'Juan Pérez', '8888-1111'),
(2, 'María López', '8888-2222'),
(3, 'Carlos Ruiz', '8888-3333');

INSERT INTO Inventario VALUES
(1, 1, 50, 20),
(1, 2, 10, 15),
(2, 1, 8, 10),
(2, 3, 30, 12),
(3, 1, 5, 10),
(3, 2, 25, 15);

INSERT INTO Pedido VALUES
(1, 1, '2026-06-01', 'Pendiente', 800.00),
(2, 1, '2026-06-03', 'Entregado', 1500.00),
(3, 2, '2026-06-04', 'Pendiente', 2500.00),
(4, 2, '2026-06-05', 'Entregado', 3500.00),
(5, 3, '2026-06-06', 'Cancelado', 400.00);

    --creación view ResumenInventario

    CREATE VIEW ResumenInventario AS
    SELECT
        m.CodigoMedicamento,
        m.Nombre AS NombreMedicamento,
        b.CodigoBodega,
        b.Nombre AS NombreBodega,
        i.Stock AS StockActual,
        i.StockMinimo,
        i.Stock - i.StockMinimo AS DiferenciaStock
    FROM Inventario i
    INNER JOIN Medicamento m
        ON i.CodigoMedicamento = m.CodigoMedicamento
    INNER JOIN Bodega b
        ON i.CodigoBodega = b.CodigoBodega;
    GO

--consulta ResumenInventario

SELECT * FROM ResumenInventario;


SELECT *
FROM ResumenInventario
WHERE DiferenciaStock < 0;


--creación view PedidosPendientes

CREATE VIEW PedidosPendientes AS
SELECT
    p.CodigoPedido,
    c.CodigoCliente,
    c.Nombre AS NombreCliente,
    p.FechaPedido,
    p.Total AS Monto
FROM Pedido p
INNER JOIN Cliente c
    ON p.CodigoCliente = c.CodigoCliente
WHERE p.Estado = 'Pendiente';
GO

--consultas PedidosPendientes
SELECT * FROM PedidosPendientes

--creación view VentasPorCliente
CREATE VIEW VentasPorCliente AS
SELECT
    c.CodigoCliente,
    c.Nombre AS NombreCliente,
    COUNT(p.CodigoPedido) AS TotalPedidos,
    SUM(p.Total) AS MontoTotalVentas
FROM Cliente c
INNER JOIN Pedido p
    ON c.CodigoCliente = p.CodigoCliente
GROUP BY
    c.CodigoCliente,
    c.Nombre;
GO

--consultas VentasPorCliente
SELECT * FROM VentasPorCliente

--procedimientos sp_a
CREATE PROCEDURE sp_a
    @NombreCliente VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM PedidosPendientes
        WHERE NombreCliente LIKE '%' + @NombreCliente + '%'
    )
    BEGIN
        SELECT
            CodigoPedido,
            NombreCliente,
            FechaPedido,
            Monto
        FROM PedidosPendientes
        WHERE NombreCliente LIKE '%' + @NombreCliente + '%';
    END
    ELSE IF EXISTS (
        SELECT 1
        FROM VentasPorCliente
        WHERE NombreCliente LIKE '%' + @NombreCliente + '%'
    )
    BEGIN
        SELECT 'El cliente existe, pero no tiene pedidos pendientes.' AS Mensaje;
    END
    ELSE
    BEGIN
        SELECT 'No existe un cliente con ese nombre o no tiene pedidos registrados.' AS Mensaje;
    END
END;
GO  

--pruebas requeridas sp_a
EXEC sp_a 'Juan';
EXEC sp_a 'Carlos';
EXEC sp_a 'David';


--procedimiento sp_b

CREATE PROCEDURE sp_b
    @NombreCliente VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM VentasPorCliente
        WHERE NombreCliente LIKE '%' + @NombreCliente + '%'
    )
    BEGIN
        SELECT
            NombreCliente,
            TotalPedidos,
            MontoTotalVentas,
            CASE
                WHEN MontoTotalVentas > 5000 THEN 'Cliente Premium'
                WHEN MontoTotalVentas BETWEEN 1000 AND 5000 THEN 'Cliente Regular'
                ELSE 'Cliente Ocasional'
            END AS Clasificacion
        FROM VentasPorCliente
        WHERE NombreCliente LIKE '%' + @NombreCliente + '%';
    END
    ELSE
    BEGIN
        SELECT 'No existe información de ventas para el cliente indicado.' AS Mensaje;
    END
END;
GO


--pruebas requeridas sp-b
EXEC sp_b 'María'
EXEC sp_b 'Juan'
EXEC sp_b 'Carlos'
EXEC sp_b 'Karen'

--procedimiento SP Transaccional ACID con Escenarios de Prueba Propios
CREATE PROCEDURE usp_RegistrarTrasladoBodega
    @CodigoMedicamento  INT,
    @CodigoBodegaOrigen INT,
    @CodigoBodegaDestino INT,
    @Cantidad           INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StockActual INT;

    BEGIN TRY

        IF @Cantidad <= 0
        BEGIN
            RAISERROR('La cantidad a trasladar debe ser mayor que cero.', 16, 1);
            RETURN;
        END;

        IF @CodigoBodegaOrigen = @CodigoBodegaDestino
        BEGIN
            RAISERROR('La bodega origen y destino no pueden ser la misma.', 16, 1);
            RETURN;
        END;

        SELECT @StockActual = Stock
        FROM Inventario
        WHERE CodigoMedicamento = @CodigoMedicamento
          AND CodigoBodega = @CodigoBodegaOrigen;

        IF @StockActual IS NULL
        BEGIN
            RAISERROR('No existe inventario del medicamento en la bodega origen.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM Inventario
            WHERE CodigoMedicamento = @CodigoMedicamento
              AND CodigoBodega = @CodigoBodegaDestino
        )
        BEGIN
            RAISERROR('No existe inventario del medicamento en la bodega destino.', 16, 1);
            RETURN;
        END;

        IF @StockActual < @Cantidad
        BEGIN
            RAISERROR('Stock insuficiente para realizar el traslado.', 16, 1);
            RETURN;
        END;

        BEGIN TRANSACTION;

            UPDATE Inventario
            SET Stock = Stock - @Cantidad
            WHERE CodigoMedicamento = @CodigoMedicamento
              AND CodigoBodega = @CodigoBodegaOrigen;

            UPDATE Inventario
            SET Stock = Stock + @Cantidad
            WHERE CodigoMedicamento = @CodigoMedicamento
              AND CodigoBodega = @CodigoBodegaDestino;

        COMMIT TRANSACTION;

        SELECT
            'Traslado realizado correctamente.' AS Mensaje,
            CodigoMedicamento,
            NombreMedicamento,
            CodigoBodega,
            NombreBodega,
            StockActual,
            StockMinimo,
            DiferenciaStock
        FROM ResumenInventario
        WHERE CodigoMedicamento = @CodigoMedicamento
          AND CodigoBodega IN (@CodigoBodegaOrigen, @CodigoBodegaDestino);

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SELECT
            'Error en el traslado. No se realizó ningún cambio en el inventario.' AS Mensaje,
            ERROR_MESSAGE() AS DetalleError;

    END CATCH
END;
GO


--escenario 1: TRASLADO EXITOSO

-- inventario antes del traslado
SELECT *
FROM Inventario
WHERE CodigoMedicamento = 2
  AND CodigoBodega IN (1, 3);

--ejecución del procedimiento
EXEC usp_RegistrarTrasladoBodega
    @CodigoMedicamento = 2,
    @CodigoBodegaOrigen = 3,
    @CodigoBodegaDestino = 1,
    @Cantidad = 5;

--inventario después del traslado
SELECT *
FROM Inventario
WHERE CodigoMedicamento = 2
  AND CodigoBodega IN (1, 3);


--escenario 2: FALLO POR STOCK INSUFICIENTE

--inventario antes del intento de traslado
SELECT *
FROM Inventario
WHERE CodigoMedicamento = 3
  AND CodigoBodega IN (1, 2);

--ejecutar el procedimiento con una cantidad mayor al stock disponible
EXEC usp_RegistrarTrasladoBodega
    @CodigoMedicamento = 3,
    @CodigoBodegaOrigen = 1,
    @CodigoBodegaDestino = 2,
    @Cantidad = 100;

-- inventario después del intento de traslado
SELECT *
FROM Inventario
WHERE CodigoMedicamento = 3
  AND CodigoBodega IN (1, 2);



--escenario 3: BODEGA DESTINO SIN INVENTARIO REGISTRADO

-- inventario antes del intento de traslado
SELECT *
FROM Inventario
WHERE CodigoMedicamento = 1;

--ejecutar el procedimiento hacia una bodega donde ese medicamento no está registrado
EXEC usp_RegistrarTrasladoBodega
    @CodigoMedicamento = 1,
    @CodigoBodegaOrigen = 1,
    @CodigoBodegaDestino = 3,
    @Cantidad = 5;

--inventario después del intento de traslado
SELECT *
FROM Inventario
WHERE CodigoMedicamento = 1;