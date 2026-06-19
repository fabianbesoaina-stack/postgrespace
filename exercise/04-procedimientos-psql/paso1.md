# Ejercicio 1 — psql, backup y usuarios

> 🎯 **Qué vas a aprender:** qué es `psql` y cómo usarlo, cómo hacer un backup desde
> pgAdmin y desde la terminal con `pg_dump`, cómo restaurar una base con `psql`, y cómo
> crear un **usuario con permisos limitados** para proteger tus datos.

---

## Paso 1.0 — Prepara tu punto de partida (¡no te lo saltes!)

Ejecuta [`setup.sql`](setup.sql) en el Query Tool de pgAdmin sobre `veterinariadb`.
Luego verifica que los datos estén completos:

```sql
SELECT (SELECT COUNT(*) FROM tutores)                  AS tutores,
       (SELECT COUNT(*) FROM mascotas)                 AS mascotas,
       (SELECT COUNT(*) FROM veterinarios)             AS veterinarios,
       (SELECT COUNT(*) FROM consultas_veterinarias)   AS consultas,
       (SELECT COUNT(*) FROM servicios)                AS servicios,
       (SELECT COUNT(*) FROM consulta_servicios)       AS relaciones;
```

Debe dar **4, 8, 3, 9, 6, 15**. ✅

---

## Paso 1.1 — ¿Qué es psql?

**pgAdmin** es la interfaz gráfica que usas cuando haces clic con el ratón. Útil para
explorar, pero no existe en un servidor real: ahí solo hay terminal.

**`psql`** es la terminal oficial de PostgreSQL. Con ella puedes hacer todo lo que haces
en pgAdmin (crear tablas, insertar datos, consultar) pero escribiendo comandos. Es lo que
usan los administradores de bases de datos en producción.

> 🎬 **Antes de continuar:** mira el video
> [Aprende a usar psql paso a paso](https://youtu.be/DmZkPTZXjNw?si=tCaUEoCgQ_IRHIqL)
> (10 min). Cubre exactamente los comandos que usarás en este set. Regresa aquí cuando
> termines.

---

## Paso 1.2 — Tu primera sesión en psql

Abre el **Terminal** integrado de VS Code (menú **Terminal → New Terminal**).
Estás dentro del contenedor donde ya vive PostgreSQL — `psql` está disponible sin instalar nada.

Conéctate a la veterinaria:

```bash
psql -U postgres -d veterinariadb
```

El prompt cambia a `veterinariadb=#`. Estás dentro. Prueba estos comandos uno por uno:

```
\l
```
Lista todas las bases de datos del servidor.

```
\dt
```
Lista las tablas de `veterinariadb`.

```sql
SELECT nombre, especie FROM mascotas LIMIT 3;
```
Una consulta real — igual que en pgAdmin, pero aquí en la terminal.

```
\du
```
Lista los **usuarios** del servidor. Ahora mismo solo hay uno: `postgres` (superusuario).

```
\conninfo
```
Muestra a qué servidor, base de datos y usuario estás conectado.

```
\q
```
Sale de psql. Vuelves al terminal normal.

> 💡 Si en algún momento el prompt cambia a `->` o `veterinariadb-#`, psql espera más
> input — generalmente falta el `;`. Escríbelo y pulsa Enter.

---

## Paso 1.3 — Backup desde pgAdmin (tu primera vez)

Antes de usar la terminal para hacer backups, hazlo desde pgAdmin para entender qué
produce un backup y dónde queda.

En pgAdmin:

1. Click derecho sobre **`veterinariadb`** en el árbol de la izquierda
2. Selecciona **Backup...**
3. En el campo **Filename** escribe: `/data/backups/veterinaria_pgadmin.sql`
4. En **Format** selecciona **Plain** (texto plano, no binario)
5. Haz clic en **Backup**

> 💡 La ruta `/data/` dentro del contenedor de pgAdmin está conectada a la carpeta
> `postgrespace/data/` de tu proyecto. El archivo aparecerá ahí automáticamente.

Cuando termine, abre el archivo desde VS Code (`data/backups/veterinaria_pgadmin.sql`).
Verás instrucciones SQL: `CREATE TABLE`, `INSERT`, `ALTER TABLE`... Ese archivo **es** tu
base de datos en texto plano. Si lo ejecutas en un servidor vacío, recrea todo.

---

## Paso 1.4 — Backup desde la terminal con `pg_dump`

`pg_dump` hace lo mismo que el backup de pgAdmin, pero desde la terminal. Es la forma
estándar en servidores donde no hay GUI.

```bash
pg_dump -U postgres -d veterinariadb > /data/backups/veterinaria_set03.sql
```

| Parte | Qué significa |
|---|---|
| `-U postgres` | usuario de PostgreSQL |
| `-d veterinariadb` | base de datos a exportar |
| `> /data/backups/veterinaria_set03.sql` | redirige la salida al archivo |

Abre el archivo desde VS Code y compáralo con el de pgAdmin: el contenido es similar.
La diferencia es que `pg_dump` lo hiciste en una línea desde la terminal, sin GUI.

---

## Paso 1.5 — Restaura en una base nueva

La restauración tiene dos pasos: crear la base destino y volcar el archivo.

**1. Crea la base destino:**

```bash
psql -U postgres -c "CREATE DATABASE veterinaria_respaldo;"
```

El flag `-c` ejecuta un comando SQL directamente desde la terminal, sin entrar al prompt.

**2. Restaura el backup:**

```bash
psql -U postgres -d veterinaria_respaldo < /data/backups/veterinaria_set03.sql
```

Verás mensajes como `SET`, `CREATE TABLE`, `INSERT`... PostgreSQL ejecuta tu archivo
línea por línea. Si termina sin `ERROR`, la restauración fue exitosa. ✅

**3. Verifica que los datos llegaron intactos:**

```bash
psql -U postgres -d veterinaria_respaldo -c "
SELECT (SELECT COUNT(*) FROM tutores)               AS tutores,
       (SELECT COUNT(*) FROM mascotas)              AS mascotas,
       (SELECT COUNT(*) FROM veterinarios)          AS veterinarios,
       (SELECT COUNT(*) FROM consultas_veterinarias) AS consultas;
"
```

Debe dar **4, 8, 3, 9**. ✅

---

## Paso 1.6 — Crea un usuario con permisos limitados

Hasta ahora todo lo haces como `postgres`, el superusuario que puede hacer cualquier cosa.
En una aplicación real esto es peligroso: si alguien roba las credenciales, tiene acceso
total. La solución es crear **usuarios con permisos mínimos**.

Vamos a crear un usuario `recepcionista` que solo puede leer (`SELECT`) la base de la
veterinaria, sin poder modificar ni borrar nada.

Abre psql como superusuario:

```bash
psql -U postgres
```

**Crea el usuario:**

```sql
CREATE USER recepcionista WITH PASSWORD 'clave123';
```

**Dale acceso a la base de datos:**

```sql
GRANT CONNECT ON DATABASE veterinariadb TO recepcionista;
```

**Dale permiso de lectura en todas las tablas:**

```sql
\c veterinariadb
GRANT SELECT ON ALL TABLES IN SCHEMA public TO recepcionista;
```

**Sale de psql:**

```
\q
```

---

## Paso 1.7 — Verifica que los permisos funcionan

Conéctate como `recepcionista`:

```bash
psql -U recepcionista -d veterinariadb
```

**Esto debe funcionar (puede leer):**

```sql
SELECT nombre, especie FROM mascotas;
```

**Esto debe fallar (no puede escribir):**

```sql
INSERT INTO mascotas (nombre, especie) VALUES ('Test', 'Gato');
```

Verás: `ERROR: permission denied for table mascotas` ✅

Eso es exactamente lo que queremos: el recepcionista puede consultar pero no modificar datos.

Sal con `\q`.

---

## Paso 1.8 — 🧪 Tu turno: usuario de solo escritura parcial

Crea un segundo usuario llamado `veterinario_app` que pueda hacer `SELECT` e `INSERT`
en `consultas_veterinarias` y `consulta_servicios`, pero **no** pueda tocar `tutores` ni
`mascotas`.

<details>
<summary>👀 Ver solución</summary>

```sql
-- Como superusuario:
psql -U postgres
```

```sql
CREATE USER veterinario_app WITH PASSWORD 'vet_clave456';
GRANT CONNECT ON DATABASE veterinariadb TO veterinario_app;
\c veterinariadb
GRANT SELECT, INSERT ON consultas_veterinarias TO veterinario_app;
GRANT SELECT, INSERT ON consulta_servicios     TO veterinario_app;
-- Solo SELECT en tablas de referencia (necesita leerlas para los JOINs)
GRANT SELECT ON tutores, mascotas, veterinarios, servicios TO veterinario_app;
```

Verifica:
```bash
psql -U veterinario_app -d veterinariadb
```
```sql
-- Funciona:
SELECT * FROM consultas_veterinarias LIMIT 2;
-- Falla:
DELETE FROM tutores WHERE id_tutor = 1;
-- ERROR: permission denied
```

</details>

---

## ✅ Lo que lograste

* **`psql`** → la terminal de PostgreSQL: navegar, consultar y administrar sin GUI.
* **`pg_dump`** → exportar una base completa como SQL portátil desde la terminal.
* **Backup en pgAdmin** → formato Plain, guardado en `/data/` (volumen compartido).
* **`psql -c`** → ejecutar un comando SQL sin entrar al prompt interactivo.
* **`psql < archivo.sql`** → restaurar una base completa desde un archivo.
* **`CREATE USER` + `GRANT`** → usuarios con permisos mínimos para proteger los datos.

> 📤 **Entrega:** guarda en `paso1.txt` el output de la terminal al ejecutar los pasos
> 1.4 y 1.5 (copia y pega el texto). Adjunta una captura del paso 1.7 donde se vea el
> `ERROR: permission denied` al intentar insertar como `recepcionista`.
> Dónde ubicar los archivos: [Entrega](ENTREGA.md).

➡️ **Siguiente:** en el [Ejercicio 2](paso2.md) crearás tu primera **función almacenada**
para encapsular consultas que usas con frecuencia.
