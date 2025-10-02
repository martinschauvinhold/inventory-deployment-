# Despliegue con Elastic Beanstalk

## Paso 1: Inicializar Elastic Beanstalk
```bash
eb init -p node.js inventory-app --region us-east-1
```

## Paso 2: Crear entorno
```bash
eb create inventory-env
```

## Paso 3: Desplegar la aplicación
```bash
eb deploy
```

## Paso 4: Comprobar URL
```bash
eb open
```

## Diferencias con EC2 manual
- Elastic Beanstalk maneja escalabilidad automática y balanceo de carga.
- No es necesario configurar puertos ni dependencias manualmente.
- Permite monitoreo y logging integrados.
