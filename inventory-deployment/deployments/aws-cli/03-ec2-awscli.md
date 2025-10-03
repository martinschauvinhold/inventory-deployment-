# 03 – Despliegue en EC2 usando AWS CLI (Windows PowerShell) — **COMPLETO**

Este documento registra **todo lo que hicimos** en el Paso 2 y deja los comandos listos para repetir el flujo sin usar la consola web.

> **Contexto concreto de esta demo**
> - Región: **`us-east-1`**
> - AMI Ubuntu 22.04: **`ami-07a3add10195338ad`**
> - Key Pair en AWS: **`millaveuade3`** (el `.pem` está en tu PC)
> - Security Group: **`sg-0dbc3fc1a0609d084`** (Inbound: SSH 22 desde tu IP, HTTP 80 abierto)
> - Resultado: instancia creada por CLI, app instalada por **User Data** y corriendo como **systemd** en **puerto 80**.

---

## 0) Prerrequisitos

```powershell
aws --version
aws configure    # Access Key / Secret / Region (us-east-1) / Output: json
```

---

## 1) Variables para la sesión (editables)

> Si cambiás de región, SG o keypair, ajustá estos valores.

```powershell
$REGION     = "us-east-1"
$AMI        = "ami-07a3add10195338ad"
$KEY_NAME   = "millaveuade3"              # nombre del key pair en AWS (sin .pem)
$SG_ID      = "sg-0dbc3fc1a0609d084"      # Security Group con 22/80
$TAG_VALUE  = "inventory-cli-demo"
```

(Comprobar key pairs disponibles)
```powershell
aws ec2 describe-key-pairs --region $REGION --query "KeyPairs[*].KeyName" --output table
```

(Confirmar que el SG tiene **22** y **80** abiertos)
```powershell
aws ec2 describe-security-group-rules --region $REGION --filter Name=group-id,Values=$SG_ID --output table
```

---

## 2) Subnet y VPC por defecto

Usamos la **VPC por defecto** y la primera **subnet por defecto** encontrada.

```powershell
$VPC_ID = aws ec2 describe-vpcs --region $REGION `
  --filters Name=isDefault,Values=true `
  --query "Vpcs[0].VpcId" --output text

$SUBNET_ID = aws ec2 describe-subnets --region $REGION `
  --filters Name=vpc-id,Values=$VPC_ID Name=default-for-az,Values=true `
  --query "Subnets[0].SubnetId" --output text

$VPC_ID; $SUBNET_ID
```

---

## 3) **User Data** — Automatiza el setup (Node 20 + app + servicio en 80)

Creamos un archivo `userdata.sh` que instalará Node.js, clonará el repo, configurará permisos para puerto 80 y levantará la app como **servicio systemd**.

```powershell
@'
#!/bin/bash
set -eux
apt update && apt upgrade -y
apt install -y git curl libcap2-bin

# Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Código
cd /opt
git clone https://github.com/josecastineiras/inventory.git
chown -R ubuntu:ubuntu inventory
cd inventory
npm install

# Permitir puerto 80 a Node sin root
setcap 'cap_net_bind_service=+ep' /usr/bin/node

# Asegurar que la app use PORT o 80 por defecto (por la consigna)
if ! grep -q "process.env.PORT" server.js; then
  sed -i "s/const PORT.*/const PORT = process.env.PORT || 80;/" server.js
fi

# Servicio systemd
cat >/etc/systemd/system/inventory.service <<'UNIT'
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
UNIT

systemctl daemon-reload
systemctl enable --now inventory
'@ | Out-File -FilePath userdata.sh -Encoding ascii
```

---

## 4) **Crear la instancia** con AWS CLI

```powershell
$INSTANCE_ID = aws ec2 run-instances --region $REGION `
  --image-id $AMI `
  --count 1 `
  --instance-type t3.micro `
  --key-name $KEY_NAME `
  --security-group-ids $SG_ID `
  --subnet-id $SUBNET_ID `
  --associate-public-ip-address `
  --user-data file://userdata.sh `
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$TAG_VALUE}]" `
  --query "Instances[0].InstanceId" --output text
$INSTANCE_ID
```

Esperar a que pase los **2/2 checks**:
```powershell
aws ec2 wait instance-status-ok --region $REGION --instance-ids $INSTANCE_ID
```

Obtener la **IP pública**:
```powershell
$PUBLIC_IP = aws ec2 describe-instances --region $REGION `
  --instance-ids $INSTANCE_ID `
  --query "Reservations[0].Instances[0].PublicIpAddress" --output text
$PUBLIC_IP
```

---

## 5) Verificación

### Desde tu PC
```powershell
# Código HTTP esperado: 200
iwr -UseBasicParsing "http://$PUBLIC_IP/" | select -ExpandProperty StatusCode
```

### (Opcional) Por SSH
```powershell
ssh -i "C:\Users\Martin\Downloads\millaveuade3.pem" ubuntu@$PUBLIC_IP
```

### Dentro del servidor (opcional)
```bash
systemctl status inventory --no-pager
curl -I http://127.0.0.1/
```

---

## 6) Troubleshooting rápido

- **No carga por navegador** pero responde localmente en `127.0.0.1`:
  - Revisar que el **Security Group** tenga `HTTP 80` abierto a `0.0.0.0/0`.
  - Confirmar que UFW en Ubuntu esté `inactive` o que permita `80/tcp`:
    ```bash
    sudo ufw status
    sudo ufw allow 80/tcp && sudo ufw reload
    ```

- **Servicio `inventory` en “failed”**:
  ```bash
  sudo journalctl -xeu inventory -n 80 --no-pager
  ```
  Errores típicos:
  - *EACCES: permission denied 80* → Falta capability:
    ```bash
    sudo apt install -y libcap2-bin
    sudo setcap 'cap_net_bind_service=+ep' /usr/bin/node
    sudo systemctl restart inventory
    ```
  - Dependencia nativa (`sqlite3`) no compiló:
    ```bash
    sudo apt install -y build-essential python3 make g++
    cd /opt/inventory && npm rebuild
    sudo systemctl restart inventory
    ```

- **User Data no corrió o falló**:
  ```bash
  sudo less /var/log/cloud-init-output.log
  ```

---

## 7) Limpieza (para no dejar costos)

```powershell
aws ec2 terminate-instances --region $REGION --instance-ids $INSTANCE_ID
aws ec2 wait instance-terminated --region $REGION --instance-ids $INSTANCE_ID

# El SG lo podés dejar para reusar; si querés borrarlo:
# aws ec2 delete-security-group --region $REGION --group-id $SG_ID
```

---

## 8) Diferencias frente al despliegue manual

- ✅ No usamos la consola web en ningún momento.
- ✅ El servidor queda configurado automáticamente con User Data.
- ✅ Repetible y versionable (scripts).
- ⚠️ Necesitás permisos de IAM para ejecutar estos comandos y acceso a la red por defecto.
