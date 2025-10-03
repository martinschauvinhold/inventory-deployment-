# 04 – Despliegue en **AWS Elastic Beanstalk** (Windows PowerShell) — Paso a paso

Elastic Beanstalk (EB) te permite desplegar la app sin ocuparte de la instancia, Nginx ni del ciclo de despliegue. EB crea/gestiona EC2, security groups, balanceador (opcional), health checks, logs y versiones de la app.

> **Importante:** En EB la aplicación **debe** escuchar el puerto provisto por la variable de entorno `PORT`.  
> Asegurate que tu `server.js` tenga algo como:
> ```js
> const PORT = process.env.PORT || 3000;
> app.listen(PORT, () => console.log(`Listening on ${PORT}`));
> ```
> (Si antes lo dejaste con `|| 80`, EB seguirá funcionando porque define `PORT`, pero para desarrollo local es mejor `3000`.)

---

## 0) Requisitos

- **AWS CLI** configurada (`aws configure`).
- **Git** instalado.
- **Python + pip** (o **pipx**) para instalar la EB CLI.

### Instalar EB CLI (elige una de las dos)
**Opción A – pipx (recomendada)**
```powershell
pipx --version
pipx install awsebcli
```

**Opción B – pip (usuario actual)**
```powershell
python -m pip install --user awsebcli
# Si no reconoce el comando 'eb', agrega Scripts al PATH, por ejemplo:
# $env:Path += ";$env:USERPROFILE\AppData\Roaming\Python\Python311\Scripts"
```

Verificar:
```powershell
eb --version
```

---

## 1) Preparar el proyecto local

Clonar (si aún no lo tienes):
```powershell
git clone https://github.com/josecastineiras/inventory.git
cd inventory
```

Asegurar `package.json`:
```json
{
  "name": "inventory",
  "version": "1.0.0",
  "scripts": {
    "start": "node server.js"
  },
  "engines": {
    "node": ">=20 <21"
  }
}
```

> **Opcional:** agrega un `Procfile` con:
> ```
> web: node server.js
> ```
> EB usará primero `Procfile` y, si no existe, usará `npm start`.

---

## 2) Inicializar Elastic Beanstalk

```powershell
# Dentro de la carpeta del proyecto
eb init
```

- Selecciona tu **región** (ej. `us-east-1`).
- Plataforma: **Node.js 20 running on 64bit Amazon Linux 2023** (o la más nueva de Node disponible).
- Cuando pregunte si usar CodeCommit: **No** (a menos que quieras).
- Acepta crear `elasticbeanstalk/config.yml`.

---

## 3) Crear el entorno

Para un entorno simple de una sola instancia (sin balanceador):

```powershell
eb create inventory-eb-dev --single --instance_types t3.micro
```

> Puedes agregar tu key pair para poder entrar por SSH a la instancia creada por EB:
> ```powershell
> eb create inventory-eb-dev --single --instance_types t3.micro --keyname millaveuade3
> ```

EB creará:
- Un **Security Group** con HTTP 80 abierto,
- Una **instancia EC2** administrada por EB,
- Una URL del tipo `http://inventory-eb-dev.<region>.elasticbeanstalk.com/`.

---

## 4) Desplegar y abrir

Si es el primer create, EB ya despliega automáticamente. Si haces cambios:

```powershell
eb deploy
eb open       # abre la URL en el navegador
```

Ver estado:
```powershell
eb status
eb health
```

---

## 5) Variables de entorno (si usas DB, etc.)

```powershell
eb setenv NODE_ENV=production
# Ejemplo para Postgres más adelante:
# eb setenv DATABASE_URL="postgres://user:pass@host:5432/dbname"
```

---

## 6) Logs y depuración

```powershell
eb logs --all        # descarga logs (app + nginx + sistema)
eb events --all      # eventos del entorno
```

Errores típicos:
- **502/503 al abrir la URL:** revisa que `npm start` exista y que la app esté escuchando en `process.env.PORT`.
- **Falló npm install / sqlite3:** la plataforma AL2023 ya trae toolchain; si usas módulos nativos, revisa logs.

---

## 7) Actualizar la app

Cada vez que hagas cambios de código:
```powershell
git add .
git commit -m "Cambios en la app"
eb deploy
```

---

## 8) Apagar/Eliminar el entorno

Para evitar costos cuando no lo uses:
```powershell
eb terminate inventory-eb-dev
```

---

## 9) Diferencias vs EC2 manual

- **EB**: subes código; la plataforma maneja Nginx, proceso Node, health checks, versiones y despliegues.
- **EC2 manual**: administras vos el SO, Node, systemd, Nginx, etc.
- **Costos**: EB agrega algo de orquestación, pero el core sigue siendo EC2; en `--single` los costos son similares a una instancia EC2 pequeña.

---

## 10) Checklist rápido

- `server.js` usa `process.env.PORT` ✔
- `package.json` tiene `"start": "node server.js"` ✔
- `eb init` con plataforma Node.js correcta ✔
- `eb create --single` ✔
- `eb open` muestra la app ✔
- Si falla: `eb logs --all`, `eb events --all` ✔
