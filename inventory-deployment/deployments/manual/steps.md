# Despliegue manual en EC2

## Paso 1: Crear instancia EC2
- Tipo de instancia: t2.micro
- Sistema operativo: Ubuntu 22.04 LTS
- Configurar grupo de seguridad: puerto 80 abierto

## Paso 2: Conectarse vía SSH
```bash
ssh -i "mi-llave.pem" ubuntu@IP_DE_LA_INSTANCIA
```

## Paso 3: Instalar dependencias
```bash
sudo apt update
sudo apt install -y nodejs npm
```

## Paso 4: Clonar el proyecto
```bash
git clone https://github.com/tuusuario/inventory-deployment.git
cd inventory-deployment/application
npm install
```

## Paso 5: Ejecutar la aplicación
```bash
sudo node index.js
```

## Automatización inicial con User Data
- Crear archivo `user_data.sh` (ejemplo abajo)
- Adjuntarlo al crear la instancia para instalar automáticamente dependencias y desplegar.
