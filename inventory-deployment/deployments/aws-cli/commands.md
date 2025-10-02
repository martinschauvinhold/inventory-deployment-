# Despliegue con AWS CLI

## Crear instancia EC2
```bash
aws ec2 run-instances   --image-id ami-0abcdef1234567890   --count 1   --instance-type t2.micro   --key-name mi-llave   --security-group-ids sg-xxxxxxxx   --subnet-id subnet-xxxxxx   --user-data file://deployments/manual/user_data.sh
```

## Conectarse a la instancia
```bash
ssh -i "mi-llave.pem" ubuntu@IP_DE_LA_INSTANCIA
```

## Comandos útiles dentro de la instancia
```bash
cd inventory-deployment/application
npm install
sudo node index.js
```
