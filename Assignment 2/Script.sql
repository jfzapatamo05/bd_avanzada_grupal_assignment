
--2. Crear una vista llamada "plan_mantenimiento_detallado"
create or replace view plan_mantenimiento_detallado as
select r.kilometraje_revision as Kilometraje,opr.operacion as Item from revisiones r inner join operaciones_revisiones opr
on r.id=opr.id_revision;

select * from plan_mantenimiento_detallado where kilometraje=10000;

---3. Crear un procedimiento almacenado llamado "Programar_mantenimiento"

CREATE OR REPLACE PROCEDURE PROGRAMAR_MANTENIMIENTO (P_ID_VEHICULO in VEHICULOS.ID%TYPE,V_KILOMETROS in VEHICULOS.KILOMETRAJE%TYPE) AS

--V_KILOMETROS VEHICULOS.KILOMETRAJE%TYPE;
V_CENTRO_RECIBO CENTRO_RECIBOS.NOMBRE%TYPE;
V_ID_MANT MANTENIMIENTOS.ID%TYPE;
KILOMETROS_FALTANTES FLOAT := 0;
EXC_ID_VEHICULO_NO_VALIDO EXCEPTION;


BEGIN

        IF P_ID_VEHICULO <=0 THEN
            RAISE EXC_ID_VEHICULO_NO_VALIDO;
        END IF;
        
    SELECT MAX(ID) INTO V_ID_MANT FROM mantenimientos;

    --SELECT c.nombre INTO V_CENTRO_RECIBO
    --FROM  CENTRO_RECIBOS C
    -- ON C.ID=V.ID_CENTRO_RECIBO
    -- WHERE V.ID = P_ID_VEHICULO 
    --GROUP BY C.NOMBRE;
        
	IF V_KILOMETROS <= 5000 THEN KILOMETROS_FALTANTES := (5000- V_KILOMETROS); 
	ELSIF V_KILOMETROS > 5000 AND V_KILOMETROS <= 10000 THEN KILOMETROS_FALTANTES := 10000 - V_KILOMETROS;
	ELSIF V_KILOMETROS > 10000 AND V_KILOMETROS <= 20000 THEN KILOMETROS_FALTANTES := 20000 - V_KILOMETROS;
	ELSIF V_KILOMETROS > 20000 AND V_KILOMETROS <= 40000 THEN KILOMETROS_FALTANTES := 40000 - V_KILOMETROS;
	ELSIF V_KILOMETROS > 40000 AND V_KILOMETROS <= 50000 THEN KILOMETROS_FALTANTES := 50000- V_KILOMETROS;
	ELSIF V_KILOMETROS > 50000 AND V_KILOMETROS <= 100000 THEN KILOMETROS_FALTANTES := 100000- V_KILOMETROS;
	END IF;  

	IF KILOMETROS_FALTANTES < 200 THEN 
        INSERT INTO MANTENIMIENTOS (ID,FECHA_MANTENIMIENTO,HORA_ENTRADA,HORA_SALIDA,ID_EMPLEADO,ESTADO,OBSERVACIONES,ID_VEHICULO,ID_REVISION)
        VALUES (V_ID_MANT+1,TO_DATE(SYSDATE +2,'dd/mm/yyyy'),TO_DATE('','HH24:MI:SS'),TO_DATE('','HH24:MI:SS'),4,'NO REALIZADO','',P_ID_VEHICULO,2);
        DBMS_OUTPUT.PUT_LINE('MANTENIMIENTO PROGRAMADO CON ÉXITO');
 
    ELSE 
    DBMS_OUTPUT.PUT_LINE('NO ES POSIBLE PROGRAMAR EL PROXIMO MANTENIMIENTO POR QUE FALTAN : ' || KILOMETROS_FALTANTES || ' KILOMETROS'  );
 
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('KILOMETROS: ' || V_KILOMETROS);
    DBMS_OUTPUT.PUT_LINE('KILOMETROS FALTANTES: ' || KILOMETROS_FALTANTES);
    DBMS_OUTPUT.PUT_LINE('CENTRO DE RECIBO: ' || V_CENTRO_RECIBO);
    DBMS_OUTPUT.PUT_LINE('ID MANTENIMIENTO: ' || V_ID_MANT);
    
    EXCEPTION
        WHEN EXC_ID_VEHICULO_NO_VALIDO THEN
        RAISE_APPLICATION_ERROR(-20001,'ID DE VEHICULO NO VALIDO');
END;

execute PROGRAMAR_MANTENIMIENTO(6,79613);

SELECT * FROM vehiculos;

--4.Crear un trigger sobre la tabla de los vehículos, cuando cambie el kilometraje de vehículo deberá invocar el 
--procedimiento "Programar_mantenimiento"
CREATE OR REPLACE TRIGGER MANTENIMIENTOS AFTER UPDATE OR INSERT ON VEHICULOS FOR EACH ROW
BEGIN
    PROGRAMAR_MANTENIMIENTO(:OLD.ID,:OLD.KILOMETRAJE);
END;

UPDATE VEHICULOS SET KILOMETRAJE= 99976 WHERE ID=20;

SELECT * FROM MANTENIMIENTOS;

--5. la junta directiva desea realizar un cotizador de precios de los envíos
CREATE TABLE COTIZADOR_PRECIOS (
	ID INTEGER PRIMARY KEY,
	CENTRO_RECIB_ID INT,
    DESTINO_ID INT,
    PRECIO_KILO DECIMAL,
    CONSTRAINT FK_CENTRO_RECIB_COTIZADOR FOREIGN KEY (CENTRO_RECIB_ID) REFERENCES CENTRO_RECIBOS (ID),
    CONSTRAINT FK_CIUDADES_DESTINO_COTIZADOR FOREIGN KEY (DESTINO_ID) REFERENCES CIUDADES(ID)
);

-- 7 
-- Crear una función que retornará un decimal, dicha función recibirá las siguientes variables:
-- peso_real, peso_volumen, centro_recibo_origen, ciudad_destino. 
-- Dicha función deberá comparar el valor mayor entre peso_real y peso_volumen,
-- con ese valor deberá buscar el precio por kilo de la ciudad hacia donde se dirige el paquete. 
-- Para esto invocará la vista del punto anterior y el precio deberá multiplicarlo 
-- Validar con excepciones que los pesos sean mayores a 0 y los centros de
-- recibo y la ciudad destino no estén en blanco.

CREATE OR REPLACE FUNCTION funcionDecimal (peso_real integer, peso_volumen integer,
                                           centro_recibo_origen integer, ciudad_destino integer) RETURN INTEGER IS
resultado integer :=0;
mayor integer  := 0;
precio_total integer  := 0;
bandera_pesos integer := 0;
begin

        IF(peso_real and peso_volumen > 0) then
        bandera_pesos := 1;
        else
        DBMS_OUTPUT.put_line('los pesos no son validos');
        end if;
        
        
            if (peso_real > peso_volumen and bandera_pesos = 1) THEN
            mayor := peso_real;
            else if(peso_volumen > peso_real  and bandera_pesos = 1) then
            mayor := peso_volumen;
            else 
            mayor:= peso_real;
            end if;
       
        
        
     --   precio_kilo := valor de la vista where ID_CIUDAD_DESTINO = (select id_ciudad from ciudades)
     
        IF(precio_kilo = 0 or precio_kilo = null ) then
        DBMS_OUTPUT.put_line('los centros de recibo o la ciudad destino en blanco');
        end if;
     
     
        precio_total := precio_kilo * mayor;
        
        
        
    RETURN precio_total;
end

-- 8

-- Crear un procedimiento llamado "calcular_fletes",
-- el cual seleccionará aquellos envíos donde el campo "valor del servicio" esté 0 o nullo. 
-- Con cada uno de ellos deberá invocar la función creada en el punto anterior y con el valor retornado,
-- deberá llenar el campo "valor del servicio".

CREATE OR REPLACE PROCEDURE calcular_fletes AS


     cursor cur is
     SELECT peso_real, peso_volumen, centro_recibo_origen, ciudad_destino
     FROM envio_mercancia
     where valor_servicio = null or valor_servicio = 0
     FOR UPDATE;
     
        resultado_function INTEGER;
     
BEGIN

   FOR dato in cur
   LOOP
      resultado_function  := funcionDecimal(dato.peso_real, dato.peso_volumen, dato.centro_recibo_origen, dato.ciudad_destino);
      UPDATE envio_mercancia set valor_servicio = resultado_function WHERE CURRENT OF cur; 
   END LOOP;
END;

-- 9
-- Crear un procedimiento llamado "calcular_peso_volumetrico",
-- dicho procedimiento deberá leer todos los registros de la tabla de envíos y llenar el 
-- campo "peso volumen", para esto aplicará la fórmula expuesta en el taller anterior: 
-- se obtiene multiplicando el ancho x el alto x el largo
-- y luego se multiplica por 400 que es el factor de equivalencia por cada metro cúbico)

CREATE OR REPLACE PROCEDURE calcular_peso_volumetrico AS

     cursor cur is
     SELECT ancho,largo,alto
     FROM envio_mercancia
     FOR UPDATE;
     
     resultado_function INTEGER;
     
BEGIN

   FOR dato in cur
   LOOP
      resultado_function  := dato.ancho*dato.largo*dato.alto*400;
      UPDATE envio_mercancia set peso_volumen = resultado_function WHERE CURRENT OF cur; 
   END LOOP;
END;



--10. calcular cajas necesarias
DECLARE 
resultado numeric := 0;
BEGIN
   -- resultado := CALCULAR_CAJAS_NECESARIAS(16,5,10);
   -- resultado := CALCULAR_CAJAS_NECESARIAS(14,10,1);
   -- resultado := CALCULAR_CAJAS_NECESARIAS(6,1,10);
    DBMS_OUTPUT.put_line('LA CANTIDAD DE CAJAS NECESARIAS SON: ' || resultado);
END;

CREATE OR REPLACE FUNCTION CALCULAR_CAJAS_NECESARIAS ( NRO_ITEMS INT,CAJAS_GRANDES  INT,CAJAS_PEQUENAS INT)
RETURN NUMERIC AS 
    CANTIDAD_CAJAS  NUMERIC := 0;
    CAPACIDAD_CAJA_GRANDE NUMERIC := 5;
    CAPACIDAD_CAJA_PEQUENA NUMERIC := 1;
    CONTADOR_CAJA_GRANDE NUMERIC := 0;
    CONTADOR_CAJA_PEQUENA NUMERIC := 0;
    ITEMS_CAJA_GRANDE NUMERIC := NRO_ITEMS;
    ITEMS_CAJA_PEQUENA NUMERIC := NRO_ITEMS;
    BANDERA_CAJA_GRANDE NUMERIC := 0;
    BANDERA_CAJA_PEQUENA NUMERIC := 0;
    BEGIN
    
    WHILE  CAPACIDAD_CAJA_GRANDE <= ITEMS_CAJA_GRANDE AND BANDERA_CAJA_GRANDE = 0
    LOOP
           IF(CONTADOR_CAJA_GRANDE < CAJAS_GRANDES )THEN
              ITEMS_CAJA_GRANDE :=  ITEMS_CAJA_GRANDE - CAPACIDAD_CAJA_GRANDE;
              CONTADOR_CAJA_GRANDE :=  CONTADOR_CAJA_GRANDE + 1;
              ELSE
              BANDERA_CAJA_GRANDE := 1;
           END IF;
    END LOOP;
    
    ITEMS_CAJA_PEQUENA := ITEMS_CAJA_GRANDE;
    
     WHILE  CAPACIDAD_CAJA_PEQUENA <= ITEMS_CAJA_PEQUENA AND BANDERA_CAJA_PEQUENA = 0
    LOOP
          IF(CONTADOR_CAJA_PEQUENA < CAJAS_PEQUENAS )THEN
         ITEMS_CAJA_PEQUENA :=  ITEMS_CAJA_PEQUENA - CAPACIDAD_CAJA_PEQUENA;
         CONTADOR_CAJA_PEQUENA :=  CONTADOR_CAJA_PEQUENA + 1;
         ELSE 
         BANDERA_CAJA_PEQUENA := 1;
         END IF;
    END LOOP;
    
    IF(ITEMS_CAJA_PEQUENA = 0) THEN
    CANTIDAD_CAJAS := CONTADOR_CAJA_GRANDE + CONTADOR_CAJA_PEQUENA;
    ELSE 
    CANTIDAD_CAJAS := -1;
    END IF;
    
    
       RETURN CANTIDAD_CAJAS;
    END;

