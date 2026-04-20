# Nivell 1

# Ejercicio 1
# Se da por entendido que anteriormente ya se ha ejecutado la estructura de la base de datos y se han insertado los datos en las distintas tablas. (Respectivos al Ejercicio 1) 
# Tablas company y transaction creadas y con datos.

#Ejercició 2

# Uso el distinct para obtener un listado de los países donde se ubican nuestros clientes, el cual no muestre los duplicados.
SELECT distinct country FROM company JOIN transaction ON company.id = transaction.company_id;

#Aquí le agrego count como operación de agregación a la query anteriormente realizada. Esta operación me retornara como resultado la cantidad de países distintos a los que pertenecen las empresas con las que trabajamos.
SELECT count(distinct country) FROM company JOIN transaction ON  company.id = transaction.company_id;

#En la tercera query quiero conocer la empresa con mayor promedio de amount. Para ello calculo el promedio de compra agrupado por compañía, lo ordeno por promedio amount DESC y al final insertamos LIMIT 1.
#Además, en el WHERE se eligen solo las transacciones que no han sido declinadas.
SELECT company_name, avg(amount) 
FROM company 
JOIN transaction ON company.id = transaction.company_id 
WHERE transaction.declined = 0
group by company_name
order by avg(amount) DESC
LIMIT 1;

#Ejercició 3
#Utilizando subquery le pido que solo me retorne los datos de transacciones correspondientes a las empresas alemanas.
SELECT id FROM transaction WHERE company_id IN (SELECT id FROM company WHERE country = 'Germany');  

#Realizo query pidiendo el nombre de las compañías que están por encima del promedio en amount, usando el método de subquery de WHERE.
SELECT company_name
FROM company
WHERE id IN (
    SELECT company_id
    FROM transaction 
    WHERE amount > (
        SELECT AVG(amount) 
        FROM transaction
    )
);   

# Busco conocer las empresas que no tienen transacciones, para ello uso la cláusula NOT IN.
SELECT c.company_name 
FROM company c 
WHERE c.id NOT IN (
	SELECT t.company_id 
    FROM transaction t);
    
#Testeo para confirmar que no haya ninguna empresa sin transacciones.
SELECT c.company_name, count(t.id)
FROM company c 
JOIN transaction t ON c.id = t.company_id
GROUP BY c.company_name
ORDER BY count(t.id);


#Nivell 2

#Ejercicio 1

#Esta query busca reconocer los cinco días con más ventas. 
#(Al no disponer de columna fecha he aplicado la función DATE sobre timestamp(fecha-hora), lo que lo convierte en fecha dentro de la query.
#Posteriormente agrupo por esta misma columna, ordeno por la suma total de amount en orden DESC y limito a cinco outputs con LIMIT 5.
SELECT DATE(timestamp), SUM(amount)
FROM transaction
WHERE declined = 0
GROUP BY DATE(timestamp)
ORDER BY sum(amount) DESC
LIMIT 5;   
#funcion DATE


#Ejercicio 2  

#En esta query agrupo país con su promedio de amount y ordenado por amount en orden descendiente. El objetivo es destacar los países con importes superiores.
SELECT company.country, avg(amount) FROM company JOIN transaction ON company.id = transaction.company_id 
WHERE declined = 0
GROUP BY company.country
ORDER BY avg(amount) DESC;  

#Ejercicio 3

# Mostra el llistat aplicant JOIN i subconsultes. 
#La query retorna las transacciones de las empresas que comparten país con ‘Non Institute’.
# Se utiliza una subquery basada en WHERE para conectar ambas tablas y abajo se realiza un Self Join (c1 y c2) para comprobar que el país coincide con el país de la empresa.

SELECT t.id
FROM transaction t
WHERE t.company_id IN
(SELECT c1.id 
FROM company c1
JOIN company c2
ON c1.country = c2.country
WHERE c2.company_name = 'Non Institute');


# Mostra el llistat aplicant solament subconsultes.
#Repito la operación anteriormente realizada, pero ahora sin utilizar JOIN's.
# Empezando por abajo, la primera query retorna el país al que pertenece ‘Non Institute’. 
# A continuación lo conectamos con la clave primaria ‘id’ de la tabla Company, para finalmente poderlo conectar con la clave foránea de la tabla transaction ‘company_id’,
# y seleccionar el id de transaction que ha pasado por los filtros anteriormente realizados.
SELECT id
FROM transaction
WHERE company_id IN(
	SELECT id 
	FROM company 
	WHERE country = (
			(SELECT country
			FROM company 
			WHERE company_name = "Non Institute")
            )
		);
        

# Nivell 3

# En esta query quiero obtener detalles de venta de las empresas. 
# Filtrando por aquellas que su amount se encuentra entre 100 y 200 usando ‘BETWEEN” y que además tengan transacciones en alguna de las 3 fechas escritas en el WHERE.
 
# Ejercicio 1 
SELECT c.company_name, c.phone,c.country,DATE(t.timestamp),t.amount
FROM company c
JOIN transaction t
ON c.id = t.company_id
WHERE t.amount BETWEEN 100 AND 200  AND  DATE(t.timestamp) IN ('2021-04-29','2021-07-20','2022-03-13')
ORDER BY t.amount DESC;

#Ejercicio 2  
# Cantidad transacciones por empresa y si tienen más de 4 o menos
#Uso de CASE para crear una columna con varias categorías, dependiendo en este caso de cuantas transacciones(t.id) tiene una misma empresa.

SELECT c.company_name, count(t.id) AS transaction_count, 
CASE WHEN count(t.id) > 4  THEN 'more than 4'
ELSE 'is 4 or lower'
END AS clasification_count
FROM company c
JOIN transaction t ON c.id = t.company_id
GROUP BY  c.company_name;

