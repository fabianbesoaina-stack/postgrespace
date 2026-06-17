-- COUNT (*) AS  FROM    (*) ---> CONTAR TODOS 
SELECT COUNT(*) AS total_mascotas FROM mascotas;
-- COUNT (*) AS FROM WHERE
SELECT COUNT(*) AS total_perros FROM mascotas WHERE especie = 'Perro';
-- SUM --> SUMA TODOS LOS VALORES
-- AVG --> HACE UN PROMEDIO
-- MIN --> EL MAS BARATO 
-- MAX --> MAS CARO
SELECT
    SUM(costo) AS total_facturado,
    AVG(costo) AS costo_promedio,
    MIN(costo) AS mas_barata,
    MAX(costo) AS mas_cara
FROM consultas_veterinarias;

