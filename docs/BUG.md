# Bug: pgAdmin no puede resolver el host 'postgres'

## Error

```
failed to resolve host 'postgres': [Errno -2] Name does not resolve
```

Se muestra en el diálogo "Connect to Server" de pgAdmin al intentar conectarse al servidor "PostgreSQL Curso".

## Causa

El `servers.json` configura `"Host": "postgres"` esperando que el DNS interno de Docker resuelva el nombre del servicio. Sin embargo, en entornos **GitHub Codespaces con `docker-outside-of-docker`**, docker-compose genera una red con nombre prefijado automáticamente (ej. `postgrespace_default`) y los contenedores pueden quedar en redes distintas, rompiendo la resolución de nombres entre servicios.

## Solución aplicada

Agregar una red explícita `pgnet` en [docker-compose.yml](../.devcontainer/docker-compose.yml) y conectar los tres servicios (`workspace`, `postgres`, `pgadmin`) a ella:

```yaml
networks:
  pgnet:
    driver: bridge

services:
  workspace:
    networks: [pgnet]
  postgres:
    networks: [pgnet]
  pgadmin:
    networks: [pgnet]
```

Con esto el DNS interno de Docker garantiza que `postgres` resuelve correctamente desde el contenedor de pgAdmin.

**Requiere:** Rebuild Container en Codespaces para que tome efecto.

---

## Opciones alternativas (si la solución anterior no funciona)

### Opción 2 — Usar `host.docker.internal`

Cambiar el `Host` en [servers.json](../.devcontainer/pgadmin/servers.json):

```json
"Host": "host.docker.internal"
```

> Solo funciona si el entorno expone `host.docker.internal` (Linux requiere agregar `--add-host=host.docker.internal:host-gateway` al servicio pgadmin en docker-compose).

### Opción 3 — Usar la IP del servicio postgres directamente

En docker-compose, asignar una IP fija al servicio postgres:

```yaml
postgres:
  networks:
    pgnet:
      ipv4_address: 172.28.0.2

networks:
  pgnet:
    driver: bridge
    ipam:
      config:
        - subnet: 172.28.0.0/16
```

Y en `servers.json` usar esa IP:

```json
"Host": "172.28.0.2"
```

### Opción 4 — Modo `network_mode: service:`

Hacer que pgAdmin comparta la red del contenedor de postgres directamente:

```yaml
pgadmin:
  network_mode: "service:postgres"
```

Y en `servers.json` usar `localhost`:

```json
"Host": "localhost"
```

> Desventaja: pgAdmin y postgres quedan en el mismo namespace de red, lo que puede causar conflictos de puertos.
