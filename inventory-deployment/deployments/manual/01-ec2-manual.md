# Despliegue Manual en EC2 (Ubuntu Server)

## 1. Crear instancia
- **AMI:** Ubuntu Server 22.04 LTS
- **Tipo:** t3.micro (o t2.micro)
- **Key pair:** tu archivo `.pem` (ej. `millaveuade3.pem`)
- **Security Group (Inbound):**
  - SSH (22) desde tu IP
  - HTTP (80) desde `0.0.0.0/0`

## 2. Conexión SSH
Desde Windows (PowerShell):
```powershell
ssh -i "C:\Users\Martin\Downloads\millaveuade3.pem" ubuntu@<IP_PUBLICA>
```
> Reemplazar `<IP_PUBLICA>` por la IP pública real (ej.: `34.224.26.219`).

## 3. Preparación del servidor
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl libcap2-bin

# Node.js 20 (NodeSource)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
node -v
```

## 4. Clonar y preparar la app
```bash
cd /opt
sudo git clone https://github.com/josecastineiras/inventory.git
sudo chown -R ubuntu:ubuntu inventory
cd inventory
npm install
```

## 5. Ajustar puerto de la app
En `server.js`, asegurar:
```js
const PORT = process.env.PORT || 80;
```
(Usamos 80 por consigna).

## 6. Permitir a Node usar el puerto 80
```bash
sudo setcap 'cap_net_bind_service=+ep' /usr/bin/node
sudo getcap /usr/bin/node   # Debe mostrar: cap_net_bind_service=ep
```

## 7. Crear servicio systemd
Archivo: `/etc/systemd/system/inventory.service`
```ini
[Unit]
Description=Inventory Node App
After=network.target

[Service]
WorkingDirectory=/opt/inventory
ExecStart=/usr/bin/env node server.js
Restart=always
RestartSec=5
Environment=PORT=80
User=ubuntu

[Install]
WantedBy=multi-user.target
```

Activar y comprobar:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now inventory
sudo systemctl status inventory --no-pager
```

## 8. Verificación
```bash
# Dentro del servidor
curl -I http://127.0.0.1/

# Desde tu PC
http://<IP_PUBLICA>/
```
