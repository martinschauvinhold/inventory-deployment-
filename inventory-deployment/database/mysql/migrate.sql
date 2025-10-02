-- Ejemplo de migración de SQLite a MySQL
CREATE DATABASE inventory_db;

USE inventory_db;

CREATE TABLE productos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    cantidad INT NOT NULL,
    precio DECIMAL(10,2) NOT NULL
);
