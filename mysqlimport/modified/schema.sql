SET NAMES utf8mb4;
  SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
  SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
  SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL';
  
  DROP SCHEMA IF EXISTS sakila;
  CREATE SCHEMA sakila;
  USE sakila;


CREATE TABLE language (
   language_id TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
   name CHAR(20) NOT NULL,
   last_update TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   PRIMARY KEY (language_id)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

 CREATE TABLE film (
   film_id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
   title VARCHAR(128) NOT NULL,
   description TEXT DEFAULT NULL,
   release_year YEAR DEFAULT NULL,
   language_id TINYINT UNSIGNED NOT NULL,
   original_language_id TINYINT UNSIGNED DEFAULT NULL,
   rental_duration TINYINT UNSIGNED NOT NULL DEFAULT 3,
   rental_rate DECIMAL(4,2) NOT NULL DEFAULT 4.99,
   length SMALLINT UNSIGNED DEFAULT NULL,
   replacement_cost DECIMAL(5,2) NOT NULL DEFAULT 19.99,
   rating ENUM('G','PG','PG-13','R','NC-17') DEFAULT 'G',
   special_features SET('Trailers','Commentaries','Deleted Scenes','Behind the Scenes') DEFAULT NULL,
   last_update TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   PRIMARY KEY  (film_id),
   KEY idx_title (title),
   KEY idx_fk_language_id (language_id),
   KEY idx_fk_original_language_id (original_language_id),
   CONSTRAINT fk_film_language FOREIGN KEY (language_id) REFERENCES language (language_id) ON DELETE RESTRICT ON UPDATE CASCADE,
   CONSTRAINT fk_film_language_original FOREIGN KEY (original_language_id) REFERENCES language (language_id) ON DELETE RESTRICT ON UPDATE CASCADE
   ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

