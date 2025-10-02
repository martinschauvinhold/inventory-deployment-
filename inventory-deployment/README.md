# Inventory Deployment Project

Este repositorio contiene el proyecto **Inventory** y distintas alternativas de despliegue en la nube.

## Contenido del repositorio

- **application/**: Código original de la aplicación.
- **deployments/manual/**: Despliegue manual en un servidor EC2 con pasos documentados y script de user data.
- **deployments/aws-cli/**: Comandos para crear instancia EC2 y desplegar usando AWS CLI.
- **deployments/elastic-beanstalk/**: Despliegue en AWS Elastic Beanstalk con instrucciones.
- **database/mysql/**: Scripts para migrar SQLite a MySQL/PostgreSQL.
- **extras/config_changes.md**: Cambios realizados, como puerto a 80 y cambio de base de datos.

## Cómo usar

1. Clonar el repositorio:
```bash
git clone https://github.com/tuusuario/inventory-deployment.git
cd inventory-deployment/application
```
2. Seguir las instrucciones en la carpeta de despliegue deseada.
3. Revisar `extras/config_changes.md` para ver cambios aplicados.
