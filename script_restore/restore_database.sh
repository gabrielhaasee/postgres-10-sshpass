#!/bin/bash

############################# AUTOR GABRIEL HAASE #############################
######################## RESTORE BASE DE DATOS DE GURI ########################

######### PARA DESCARGAR EL DUMP DEL FTP SE DEBERA DESCARGAR sshpass #########

################## EJECUCION DE SCRIPT ./restore_database.sh ##################
### SE PODRA EJECUTAR EL SCRIPT COMO TAREA AUTOMATICA PARA EL SABADO 22 HS ####
############# dia(*) hora(*) dia_del_mes(*) mes(*) dia_semana(*) ##############
########### 0 22 * * 6 /var/lib/postgresql/data/restore_database.sh ###########

####VARIABLES
set -e

NOW=$(date +"%Y%m%d") -1
NOW=$((NOW-1))

DUMP='NEME_DUMP'

BACKUP_DIR=/var/lib/postgresql/data

DATABASE=DATABASE
DATABASE_OLD=DATABASE_OLD

COMIENZODIA=$(date +"%Y_%m_%d")
COMIENZOHORA=$(date +"%T")

SCRIPT=ScriptINI.sql

###########

echo "--------------------------------------------------"
echo "DESCARGANDO DUMP DEL FTP" &> restore.log
echo "NOMBRE: $DUMP" &>> restore.log
echo "get $DUMP" | sshpass -p nimdac3ip! sftp -P 3322 -o "StrictHostKeyChecking no" guri@190.64.137.62 
echo "DUMP : $DUMP DESCARGADO"
echo "--------------------------------------------------"
echo "COMENZANDO TAREA DE RESTAURACION $COMIENZODIA $COMIENZOHORA" &>> restore.log

echo "CERRANDO CONEXIONES $DATABASE_OLD" &>> restore.log
psql -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$DATABASE_OLD' AND pid <> pg_backend_pid();" &>> restore.log
psql -c 'drop database IF EXISTS "DATABASE_OLD";' &>> restore.log

psql -c 'create database "DATABASE_OLD";' &>> restore.log

echo "REALIZANDO EL RESTORE" &>> restore.log
pg_restore -d $DATABASE_OLD < $BACKUP_DIR/$DUMP &>> restore.log

echo "EJECUTANDO SCRIPT EN BASE $DATABASE_OLD" &>> restore.log
psql -d $DATABASE_OLD < $BACKUP_DIR/$SCRIPT &>> restore.log 

echo "CERRANDO CONEXIONES $DATABASE" &>> restore.log
psql -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$DATABASE' AND pid <> pg_backend_pid();" &>> restore.log
echo "RENOMBRANDO $DATABASE A guri_prod_oldold" &>> restore.log
psql -c 'ALTER DATABASE "$DATABASE" RENAME TO "guri_prod_oldold";' &>> restore.log

echo "CERRANDO CONEXIONES $DATABASE_OLD" &>> restore.log
psql -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$DATABASE_OLD' AND pid <> pg_backend_pid();" &>> restore.log
echo "RENOMBRANDO $DATABASE_OLD A $DATABASE" &>> restore.log
psql -c 'ALTER DATABASE "$DATABASE_OLD" RENAME TO "$DATABASE";' &>> restore.log

echo "RENOMBRANDO guri_prod_oldold A $DATABASE_OLD" &>> restore.log
psql -c 'ALTER DATABASE "guri_prod_oldold" RENAME TO "$DATABASE_OLD";' &>> restore.log

echo " RESPALDO FINALIZADO :)" &>> restore.log

echo "--------------------------------------------------"
echo "BORRANDO RESPALDO: $DUMP"
rm -rf $DUMP 


