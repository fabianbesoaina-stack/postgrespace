# Ejercicio 3 — CRUD completo desde Python

> 🎯 **Qué vas a aprender:** a insertar, actualizar y eliminar datos desde Python
> usando `commit()` para confirmar los cambios en la base de datos.

---

## Paso 3.0 — Por qué existe `commit()`

PostgreSQL trabaja con **transacciones**: los cambios (INSERT, UPDATE, DELETE) no
quedan guardados permanentemente hasta que los confirmas con `COMMIT`.

En psycopg2, cada conexión empieza en modo transacción. Tú controlas cuándo confirmar:

```python
conn.commit()   # confirma los cambios → quedan guardados
conn.rollback() # cancela los cambios → vuelve al estado anterior
```

Si el script falla antes del `commit()`, PostgreSQL descarta los cambios automáticamente.
Eso es exactamente lo que quieres: o todo se guarda, o nada.

---

## Paso 3.1 — INSERT: registra una mascota nueva

Crea `paso3.py`:

```python
import psycopg2

conn = psycopg2.connect(
    host="localhost",
    database="veterinariadb",
    user="postgres",
    password="1234"
)
cursor = conn.cursor()

# INSERT con parámetros y RETURNING para obtener el id generado
cursor.execute("""
    INSERT INTO mascotas (nombre, especie, raza, fecha_nacimiento, tutor_id)
    VALUES (%s, %s, %s, %s, %s)
    RETURNING id_mascota;
""", ("Thor", "Perro", "Golden Retriever", "2022-03-15", 2))

id_nuevo = cursor.fetchone()[0]
conn.commit()

print(f"Mascota registrada con id: {id_nuevo}")
```

> 🔎 `RETURNING id_mascota` hace que PostgreSQL devuelva el id asignado por el
> `SERIAL`. Lo capturamos con `fetchone()[0]` antes del `commit()`.

---

## Paso 3.2 — UPDATE: actualiza un dato

Agrega esto al script (antes del `close()`):

```python
# Actualiza la raza de la mascota recién creada
cursor.execute("""
    UPDATE mascotas SET raza = %s WHERE id_mascota = %s;
""", ("Labrador Retriever", id_nuevo))

filas_afectadas = cursor.rowcount
conn.commit()

print(f"Actualización: {filas_afectadas} fila(s) modificada(s)")
```

> 🔎 `cursor.rowcount` indica cuántas filas afectó la última operación.
> Es útil para verificar que el UPDATE sí encontró la fila.

---

## Paso 3.3 — SELECT de verificación

Antes de borrar, verifica que los cambios están en la base:

```python
cursor.execute("""
    SELECT id_mascota, nombre, especie, raza FROM mascotas WHERE id_mascota = %s;
""", (id_nuevo,))

mascota = cursor.fetchone()
print(f"\nVerificación: {mascota}")
```

---

## Paso 3.4 — DELETE: elimina el registro de prueba

```python
# Elimina la mascota de prueba
cursor.execute("DELETE FROM mascotas WHERE id_mascota = %s;", (id_nuevo,))
conn.commit()

print(f"Mascota id {id_nuevo} eliminada")

# Confirma que ya no existe
cursor.execute("SELECT COUNT(*) FROM mascotas WHERE id_mascota = %s;", (id_nuevo,))
conteo = cursor.fetchone()[0]
print(f"Filas con ese id después del DELETE: {conteo}")  # debe ser 0

cursor.close()
conn.close()
```

Ejecuta el script completo:

```bash
python3 entregas/apellido_nombre/06-python-veterinaria/paso3.py
```

Resultado esperado:

```
Mascota registrada con id: 9
Actualización: 1 fila(s) modificada(s)

Verificación: (9, 'Thor', 'Perro', 'Labrador Retriever')
Mascota id 9 eliminada
Filas con ese id después del DELETE: 0
```

---

## Paso 3.5 — Manejo de errores con rollback

En producción siempre proteges las operaciones con `try/except`:

```python
try:
    cursor.execute("""
        INSERT INTO mascotas (nombre, especie, tutor_id)
        VALUES (%s, %s, %s);
    """, ("Error_test", "Gato", 9999))  # tutor_id 9999 no existe → FK error

    conn.commit()
    print("Insertado")

except psycopg2.Error as e:
    conn.rollback()  # cancela la transacción rota
    print(f"Error: {e}")
    print("Cambios revertidos")
```

Esto inserta un tutor_id que no existe → PostgreSQL rechaza la FK → Python captura
el error → `rollback()` limpia la transacción → la base queda intacta.

---

## Paso 3.6 — 🧪 Tu turno: función de registro

Encapsula el INSERT de mascota en una función Python que reciba los datos como
parámetros y devuelva el id generado.

<details>
<summary>👀 Ver solución</summary>

```python
def registrar_mascota(conn, nombre, especie, raza, fecha_nac, tutor_id):
    cursor = conn.cursor()
    try:
        cursor.execute("""
            INSERT INTO mascotas (nombre, especie, raza, fecha_nacimiento, tutor_id)
            VALUES (%s, %s, %s, %s, %s)
            RETURNING id_mascota;
        """, (nombre, especie, raza, fecha_nac, tutor_id))
        id_nuevo = cursor.fetchone()[0]
        conn.commit()
        return id_nuevo
    except psycopg2.Error as e:
        conn.rollback()
        print(f"Error al registrar: {e}")
        return None
    finally:
        cursor.close()

# Uso:
conn = psycopg2.connect(host="localhost", database="veterinariadb",
                        user="postgres", password="1234")
id_m = registrar_mascota(conn, "Luna", "Gato", "Siamés", "2021-06-01", 3)
print(f"Nueva mascota id: {id_m}")
conn.close()
```

</details>

---

## ✅ Lo que lograste

| Operación | Python |
|---|---|
| INSERT | `cursor.execute("INSERT ...", (valores,))` + `conn.commit()` |
| RETURNING | `cursor.fetchone()[0]` después del INSERT |
| UPDATE | `cursor.execute("UPDATE ...", (valor, id))` + `conn.commit()` |
| DELETE | `cursor.execute("DELETE ...", (id,))` + `conn.commit()` |
| Filas afectadas | `cursor.rowcount` |
| Error + rollback | `try/except psycopg2.Error` + `conn.rollback()` |

> 📤 **Entrega:** `paso3.py` con el CRUD completo (INSERT + UPDATE + SELECT +
> DELETE + manejo de error) + `paso3.png` con captura del output mostrando las
> 4 operaciones.
> Dónde ubicar los archivos: [Entrega](ENTREGA.md).

> 🎓 **Has completado el Set 05.** Ahora sabes conectar Python a PostgreSQL y
> hacer operaciones reales contra una base de datos.
> En el [Set 06](../06-proyecto-propio/README.md) diseñas y construyes
> **tu propia base de datos** desde cero.
