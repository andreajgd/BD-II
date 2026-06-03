create trigger trg_proyectos_update
ON dbo.Proyectos after update 
as
begin 
update Proyectos set update_at = GETDATE()
	from Proyectos p 
	inner join inserted i on p.ProyectoID = i.ProyectoID
end

select * from Proyectos
update proyectos set presupuesto = 2000 where ProyectoID = 1
update proyectos set is_active = 1


--crear una tabla llamada TblAuditoria(id, usuario, accion y hora 
--debe crear un trigger por cada operacion del crud que se realiza en todas las tablas 

CREATE TABLE dbo.TblAuditoria (
    id INT IDENTITY(1,1) PRIMARY KEY,
    usuario NVARCHAR(100) NOT NULL,
    tabla NVARCHAR(100) NOT NULL,
    accion NVARCHAR(20) NOT NULL,
    hora DATETIME NOT NULL
);
GO

--triggers asignaciones
CREATE OR ALTER TRIGGER trg_asignaciones_insert
ON dbo.Asignaciones AFTER INSERT
AS
BEGIN
    UPDATE a 
    SET created_at = GETDATE(),
        is_active = 1
    FROM dbo.Asignaciones a
    INNER JOIN inserted i 
        ON a.AsignacionID = i.AsignacionID
END
GO

CREATE OR ALTER TRIGGER trg_asignaciones_update
ON dbo.Asignaciones AFTER UPDATE
AS
BEGIN
    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    UPDATE a 
    SET updated_at = GETDATE()
    FROM dbo.Asignaciones a
    INNER JOIN inserted i 
        ON a.AsignacionID = i.AsignacionID
END
GO

CREATE OR ALTER TRIGGER trg_asignaciones_delete
ON dbo.Asignaciones INSTEAD OF DELETE
AS
BEGIN
    UPDATE a 
    SET deleted_at = GETDATE(),
        is_active = 0
    FROM dbo.Asignaciones a
    INNER JOIN deleted d 
        ON a.AsignacionID = d.AsignacionID
END
GO

--triggers departamentos 
CREATE OR ALTER TRIGGER trg_departamentos_insert
ON dbo.Departamentos AFTER INSERT
AS
BEGIN
    UPDATE d 
    SET created_at = GETDATE(),
        is_active = 1
    FROM dbo.Departamentos d
    INNER JOIN inserted i 
        ON d.DepartamentoID = i.DepartamentoID
END
GO

CREATE OR ALTER TRIGGER trg_departamentos_update
ON dbo.Departamentos AFTER UPDATE
AS
BEGIN
    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    UPDATE d 
    SET updated_at = GETDATE()
    FROM dbo.Departamentos d
    INNER JOIN inserted i 
        ON d.DepartamentoID = i.DepartamentoID
END
GO

CREATE OR ALTER TRIGGER trg_departamentos_delete
ON dbo.Departamentos INSTEAD OF DELETE
AS
BEGIN
    UPDATE d 
    SET deleted_at = GETDATE(),
        is_active = 0
    FROM dbo.Departamentos d
    INNER JOIN deleted del 
        ON d.DepartamentoID = del.DepartamentoID
END
GO

--triggers empleados 
CREATE OR ALTER TRIGGER trg_empleados_insert
ON dbo.Empleados AFTER INSERT
AS
BEGIN
    UPDATE e 
    SET created_at = GETDATE(),
        id_active = 1
    FROM dbo.Empleados e
    INNER JOIN inserted i 
        ON e.EmpleadoID = i.EmpleadoID
END
GO

CREATE OR ALTER TRIGGER trg_empleados_update
ON dbo.Empleados AFTER UPDATE
AS
BEGIN
    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    UPDATE e 
    SET updated_at = GETDATE()
    FROM dbo.Empleados e
    INNER JOIN inserted i 
        ON e.EmpleadoID = i.EmpleadoID
END
GO

CREATE OR ALTER TRIGGER trg_empleados_delete
ON dbo.Empleados INSTEAD OF DELETE
AS
BEGIN
    UPDATE e 
    SET deleted_at = GETDATE(),
        id_active = 0
    FROM dbo.Empleados e
    INNER JOIN deleted d 
        ON e.EmpleadoID = d.EmpleadoID
END
GO

--triggers para proyectos 
CREATE OR ALTER TRIGGER trg_proyectos_insert
ON dbo.Proyectos AFTER INSERT
AS
BEGIN
    UPDATE p 
    SET created_at = GETDATE(),
        is_active = 1
    FROM dbo.Proyectos p
    INNER JOIN inserted i 
        ON p.ProyectoID = i.ProyectoID
END
GO

CREATE OR ALTER TRIGGER trg_proyectos_update
ON dbo.Proyectos AFTER UPDATE
AS
BEGIN
    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    UPDATE p 
    SET update_at = GETDATE()
    FROM dbo.Proyectos p
    INNER JOIN inserted i 
        ON p.ProyectoID = i.ProyectoID
END
GO

CREATE OR ALTER TRIGGER trg_proyectos_delete
ON dbo.Proyectos INSTEAD OF DELETE
AS
BEGIN
    UPDATE p 
    SET delete_at = GETDATE(),
        is_active = 0
    FROM dbo.Proyectos p
    INNER JOIN deleted d 
        ON p.ProyectoID = d.ProyectoID
END
GO