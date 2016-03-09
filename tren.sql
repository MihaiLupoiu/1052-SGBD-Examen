createdb -h db-aules.uji.es al204332_trenes
psql -h db-aules.uji.es al204332_trenes

--creación Base de datos: 
CREATE TABLE Empleados (
	cod_empleado SERIAL, 
	nombre VARCHAR(20), 
	email VARCHAR(20), 
	edad INTEGER, 
	CONSTRAINT cp_Empleados PRIMARY KEY ( cod_empleado )
);

CREATE TABLE Conductores (
	cod_empleado    INTEGER, 
	horas_Act       INTEGER,
	horas_max       INTEGER,
	CONSTRAINT 		cp_Conductores PRIMARY KEY (cod_empleado),
	CONSTRAINT 		ca_Conductores FOREIGN KEY (cod_empleado)
		            REFERENCES Empleados 
	                ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE Revisores (
	cod_empleado    INTEGER, 
	turno           VARCHAR(10),
	cargo           VARCHAR(20),
	CONSTRAINT      cp_Revisores PRIMARY KEY (cod_empleado),
    CONSTRAINT 		ca_Revisores FOREIGN KEY (cod_empleado)
	                REFERENCES Empleados 
	                ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE Trenes (
	cod_tren        SERIAL,
	nombre          VARCHAR(20),
	origen          VARCHAR(20),
	destino         VARCHAR(20),
	duracion        VARCHAR(20),
	cod_empleado    INTEGER,
	horario         VARCHAR(200),
	CONSTRAINT 		cp_Trenes PRIMARY KEY ( cod_tren ),
    CONSTRAINT 		ca_Trenes FOREIGN KEY (cod_empleado)
                    REFERENCES Conductores
	                ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE Controla (
	cod_tren        INTEGER,
	cod_empleado    INTEGER,
	CONSTRAINT 		cp_Controla PRIMARY KEY ( cod_tren, cod_empleado),
	CONSTRAINT 		ca_ControlaTren FOREIGN KEY (cod_tren)
	                REFERENCES Trenes
	                ON DELETE RESTRICT ON UPDATE RESTRICT,
	CONSTRAINT 		ca_ControlaRevisores FOREIGN KEY (cod_empleado)	
	                REFERENCES Revisores 
	                ON DELETE RESTRICT ON UPDATE RESTRICT
);

--Eliminar base de datos:
DROP TABLE CONTROLA,REVISORES,CONDUCTORES,TRENES,EMPLEADOS CASCADE;

--Datos:
--Empleados
INSERT INTO Empleados (nombre, email, edad) VALUES ('Jose Garcia', 'jgarcia@gmail.com', 35);
INSERT INTO Empleados (nombre, email, edad) VALUES ('Antonio Jose', 'ajose@gmail.com', 42);
INSERT INTO Empleados (nombre, email, edad) VALUES ('Jesus Gonzalez', 'jgonzalez@gmail.com', 38);
INSERT INTO Empleados (nombre, email, edad) VALUES ('Carlos Remon', 'cremon@gmail.com', 47);

INSERT INTO Empleados (nombre, email, edad) VALUES ('Juan Jose', 'jjose@gmail.com', 29);
INSERT INTO Empleados (nombre, email, edad) VALUES ('Alex Beltran', 'abeltran@gmail.com', 22);

--Conductores
INSERT INTO Conductores VALUES (1, 8, 12);
INSERT INTO Conductores VALUES (2, 3, 12);

INSERT INTO Conductores VALUES (5, 4, 12);
--Revisores
INSERT INTO Revisores VALUES (3, 'dia', 'Responsable');
INSERT INTO Revisores VALUES (4, 'noche', 'Revisor');

INSERT INTO Revisores VALUES (6, 'dia', 'Revisor');
--Trenes
INSERT INTO Trenes (nombre, origen, destino, duracion, cod_empleado, horario) VALUES ('ALVIA 04111','Castellon','Madrid','3 h. 3 min.',1,'Tren Fuera de horario');
INSERT INTO Trenes (nombre, origen, destino, duracion, cod_empleado, horario) VALUES ('EUROMED 01091','Castellon','Valencia','49 min.',1,'Tren Fuera de horario');
INSERT INTO Trenes (nombre, origen, destino, duracion, cod_empleado, horario) VALUES ('EUROMED 01472','Castellon','Barcelona','2 h. 17 min.',2,'Tren Fuera de horario');

INSERT INTO Trenes (nombre, origen, destino, duracion, cod_empleado, horario) VALUES ('ALVIA 04111','Madrid','Castellon','3 h. 10 min.',5,'Tren Fuera de horario');
--Controla
INSERT INTO Controla VALUES (1, 3);
INSERT INTO Controla VALUES (2, 4);

INSERT INTO Controla VALUES (4, 6);

-- Versión 2.0 
CREATE VIEW Infotrenes AS
	SELECT T.cod_tren as Tren, T.origen || ' - ' || T.destino AS trayecto, 
	T.cod_empleado, E.nombre AS conductor,  COALESCE(R.nombre,'Sin asignar') as revisor
	FROM Trenes AS T 
		LEFT JOIN Empleados AS E USING (cod_empleado)
		LEFT JOIN
		( 	SELECT CO.cod_tren, E.nombre
			FROM Controla as CO
				JOIN Empleados AS E USING (cod_empleado)
			) AS R USING (cod_tren)
	WHERE UPPER(T.origen) like 'CASTELLON';

-- Ejercicio 2 Crea un disparador que permita actualizar el conductor del tren 
--(solo el id) mediante la vista. Independientemente de cómo la hayas creado, 
--el disparador mantener la restricción WITH CHECK OPTION a la vista. 
--¿Qué crees que pasará con el nombre del conductor? Razona tu respuesta.

CREATE OR REPLACE FUNCTION actualizarConductor() RETURNS TRIGGER AS '
  DECLARE
    id INTEGER;
    id_tren INTEGER;
  BEGIN

	SELECT COUNT(cod_empleado) INTO id
    FROM   conductores 
    WHERE  cod_empleado = NEW.cod_empleado;

    SELECT tren INTO id_tren
    FROM   infotrenes
    WHERE  cod_empleado = OLD.cod_empleado;
  	IF (id > 0) THEN
  		UPDATE trenes 
  		SET cod_empleado = NEW.cod_empleado 
  		WHERE cod_empleado = OLD.cod_empleado
  		AND cod_tren = id_tren;
    ELSIF (id < 1) THEN
   		RAISE EXCEPTION ''El codigo empleado % no esta el la lista de conductores'', NEW.cod_empleado;
    END IF;

    RETURN NEW;
  END;
' LANGUAGE 'plpgsql';

CREATE TRIGGER actualizaConductorTrenes
	INSTEAD OF UPDATE ON infotrenes
	FOR EACH ROW
	EXECUTE PROCEDURE actualizarConductor();

UPDATE infotrenes
SET cod_empleado=5
WHERE cod_empleado=2;

-- Ejercicio 3

ALTER TABLE conductores ADD COLUMN num_trenes INTEGER NOT NULL DEFAULT 0;

-- TRIGGERS:

-- TRENES:
CREATE OR REPLACE FUNCTION trenesConductor() RETURNS TRIGGER AS '
    DECLARE
        numero_trenes INTEGER;
    BEGIN
  
        IF TG_OP = ''INSERT'' OR TG_OP = ''UPDATE'' THEN
    
            SELECT COUNT(*) INTO numero_trenes
            FROM Trenes
            WHERE cod_empleado=NEW.cod_empleado;
    
            UPDATE conductores
            SET num_trenes=numero_trenes
            WHERE cod_empleado=NEW.cod_empleado;

            IF TG_OP = ''UPDATE'' THEN
                UPDATE conductores
                SET num_trenes=numero_trenes
                WHERE cod_empleado=OLD.cod_empleado;
            END IF;
        ELSE 
            SELECT COUNT(*) INTO numero_trenes
            FROM Trenes
            WHERE cod_empleado=OLD.cod_empleado;

            UPDATE conductores
            SET num_trenes=numero_trenes
            WHERE cod_empleado=OLD.cod_empleado;
        END IF;
        RETURN NEW;
    END;
' LANGUAGE 'plpgsql';

CREATE TRIGGER trenesConductor
    AFTER INSERT OR UPDATE OR DELETE ON Trenes
    FOR EACH ROW
    EXECUTE PROCEDURE trenesConductor();

-- CONDUCTORES:
CREATE OR REPLACE FUNCTION conductorTrenes() RETURNS TRIGGER AS '
    DECLARE    
        numero_trenes INTEGER;
    BEGIN

        SELECT COUNT(*) INTO numero_trenes
        FROM TRENES
        WHERE cod_empleado = NEW.cod_empleado;

        IF NEW.num_trenes != numero_trenes THEN
            NEW.num_trenes = numero_trenes;
        END IF;
  
    RETURN NEW;
  END;
' LANGUAGE 'plpgsql';

CREATE TRIGGER conductorTrenes
    BEFORE INSERT OR UPDATE ON Conductores
    FOR EACH ROW
    EXECUTE PROCEDURE conductorTrenes();

-- Ejercicio 4
CREATE UNIQUE INDEX name ON table (column [, ...]);


