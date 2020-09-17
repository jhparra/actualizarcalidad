#!/bin/sh
#
# Version 10-09-2018
#
#echo -n "Nombre de usuario que restaura : "
#read RESTAURA_USER
export RESTAURA_USER="restaurar_user"
#echo -n "Password del usuario : "
#read PASSWD
#export PGPASSWORD=$PASSWD
export PGPASSWORD="AWJE0LFZRaxjxST"
echo -n "Nombre de la copia de seguridad a utilizar : "
read COPIABD
echo "Creando la base de datos tmp_sanos_test ... \n"
psql -h localhost -U $RESTAURA_USER postgres -c "CREATE DATABASE tmp_sanos_test"
echo "Restaurando la base de datos usando la copia ... \n"
psql -h localhost -U $RESTAURA_USER tmp_sanos_test < $COPIABD
echo "Creando funcion para otorgar permisos a usuarios ... \n"
psql -h localhost -U $RESTAURA_USER -c "CREATE OR REPLACE FUNCTION grant_all_in_schema (schname name, grant_to name) RETURNS integer AS ' DECLARE   rel RECORD; BEGIN   EXECUTE ''GRANT ALL ON SCHEMA ''|| quote_ident(schname) || '' TO '' || quote_ident(grant_to);   FOR rel IN  SELECT tablename FROM pg_tables WHERE schemaname = schname   LOOP  EXECUTE ''GRANT ALL PRIVILEGES ON '' || quote_ident(schname) || ''.'' || rel.tablename || '' TO '' || quote_ident(grant_to);   END LOOP;   RETURN 1; END; ' LANGUAGE plpgsql STRICT;" tmp_sanos_test
psql -h localhost -U $RESTAURA_USER -c "CREATE OR REPLACE FUNCTION public.asignar_permisos(nombre_usuario character varying) RETURNS void AS 'DECLARE  esquema RECORD; tabla RECORD; secuencia RECORD; v_esquema character varying; v_tabla character varying; v_secuencia character varying;  BEGIN FOR esquema IN SELECT DISTINCT ON (schemaname) schemaname FROM pg_tables WHERE schemaname NOT IN (''information_schema'',''pg_catalog'') LOOP   v_esquema= esquema.schemaname;   PERFORM grant_all_in_schema(v_esquema,nombre_usuario); END LOOP;  END;'  LANGUAGE plpgsql VOLATILE  COST 100;" tmp_sanos_test
echo "Truncando tablas en la base de datos tmp_sanos_test ... \n"
psql -h localhost -U $RESTAURA_USER -c "TRUNCATE TABLE xfm_sgd_accion RESTART IDENTITY CASCADE;TRUNCATE TABLE xfm_sgd_rol RESTART IDENTITY CASCADE;TRUNCATE TABLE xfm_sgd_proceso RESTART IDENTITY CASCADE;TRUNCATE TABLE xfm_sgd_menu RESTART IDENTITY CASCADE;" tmp_sanos_test 
echo "Creacion de tabla en test ... \n"
psql -h localhost -U $RESTAURA_USER -c 'create table usuariosamb as (select * from usuario_ambulatorio)' sanos_test 
psql -h localhost -U $RESTAURA_USER -c 'create table usuarios as (select * from xfm_sgd_usuario)' sanos_test 
psql -h localhost -U $RESTAURA_USER -c 'create table medicos as (select * from medico)' sanos_test
psql -h localhost -U $RESTAURA_USER -c "create table medicoespec as (select * from medico_especialidad where medico in (select id from xfm_sgd_usuario where login in ('cardiologo_test','cardiologohigea_test','hematologo_test','medicinainterna_test','Neurologo_test','nutricionista_test')))" sanos_test  
psql -h localhost -U $RESTAURA_USER -c "create table horariomed as (select * from horario_medico where medico in (select id from xfm_sgd_usuario where login in ('cardiologo_test','cardiologohigea_test','hematologo_test','medicinainterna_test','Neurologo_test','nutricionista_test')))" sanos_test  
echo "Creacion de tabla en tmp ... \n"
psql -h localhost -U $RESTAURA_USER -c 'create table usuariosamb as (select * from usuario_ambulatorio where usuario != usuario)' tmp_sanos_test
psql -h localhost -U $RESTAURA_USER -c 'create table usuarios as (select * from xfm_sgd_usuario where id != id)' tmp_sanos_test
psql -h localhost -U $RESTAURA_USER -c 'create table medicos as (select * from medico where medico != medico)' tmp_sanos_test
psql -h localhost -U $RESTAURA_USER -c 'create table medicoespec as (select * from medico_especialidad where medico != medico)' tmp_sanos_test  
psql -h localhost -U $RESTAURA_USER -c 'create table horariomed as (select * from horario_medico where medico != medico)' tmp_sanos_test  
echo "Restableciendo registros en la nueva base de datos ... \n"
pg_dump -h localhost -U $RESTAURA_USER -a -t usuariosamb sanos_test |psql -h localhost -U $RESTAURA_USER tmp_sanos_test
pg_dump -h localhost -U $RESTAURA_USER -a -t usuarios sanos_test |psql -h localhost -U $RESTAURA_USER tmp_sanos_test
pg_dump -h localhost -U $RESTAURA_USER -a -t medicos sanos_test |psql -h localhost -U $RESTAURA_USER tmp_sanos_test
pg_dump -h localhost -U $RESTAURA_USER -a -t medicoespec sanos_test |psql -h localhost -U $RESTAURA_USER tmp_sanos_test
pg_dump -h localhost -U $RESTAURA_USER -a -t horariomed sanos_test |psql -h localhost -U $RESTAURA_USER tmp_sanos_test
pg_dump -h localhost -U $RESTAURA_USER -a -t xfm_sgd_accion sanos_test |psql -h localhost -U $RESTAURA_USER tmp_sanos_test
pg_dump -h localhost -U $RESTAURA_USER -a -t xfm_sgd_rol sanos_test |psql -h localhost -U $RESTAURA_USER tmp_sanos_test
pg_dump -h localhost -U $RESTAURA_USER -a -t xfm_sgd_proceso sanos_test |psql -h localhost -U $RESTAURA_USER tmp_sanos_test
pg_dump -h localhost -U $RESTAURA_USER -a -t xfm_sgd_menu sanos_test |psql -h localhost -U $RESTAURA_USER tmp_sanos_test
pg_dump -h localhost -U $RESTAURA_USER -a -t xfm_sgd_menu_accion sanos_test |psql -h localhost -U $RESTAURA_USER tmp_sanos_test
pg_dump -h localhost -U $RESTAURA_USER -a -t xfm_sgd_menu_arbol sanos_test |psql -h localhost -U $RESTAURA_USER tmp_sanos_test
#psql -h localhost -U $RESTAURA_USER -c "update xfm_sgd_usuario set login = 'BORRAR' where id = 'c5104bae-c0f8-11e8-ad0a-1293eba9db62';insert into xfm_sgd_usuario (id, login, activo, documento, nombres, apellidos, nacionalidad, email, clave)"
psql -h localhost -U $RESTAURA_USER -c "UPDATE xfm_sgd_usuario set login = 'DUPLICADO_'||CEIL(RANDOM() * 100000000)||'_'||CEIL(RANDOM() * 100000) where id in (select idprod from (select usu.id as idtest, xfm.id as idprod from usuarios usu inner join xfm_sgd_usuario xfm on usu.login = xfm.login) c where c.idtest != c.idprod);insert into xfm_sgd_usuario (id, login, activo, documento, nombres, apellidos, nacionalidad, email, clave)
select t.id,t.login,t.activo,t.documento,t.nombres,t.apellidos,t.nacionalidad,t.email,t.clave from usuarios t left join xfm_sgd_usuario x on t.id = x.id where x.id is null;" tmp_sanos_test
psql -h localhost -U $RESTAURA_USER -c"insert into usuario_ambulatorio (usuario, ambulatorio, activo, usuario_reg, fecha_reg, usuario_mod,fecha_mod, departamento)
select t.usuario, t.ambulatorio, t.activo, t.usuario_reg, t.fecha_reg, t.usuario_mod,t.fecha_mod, t.departamento from usuariosamb t
left join usuario_ambulatorio x on t.usuario = x.usuario where x.usuario is null;" tmp_sanos_test
psql -h localhost -U $RESTAURA_USER -c'insert into medico (medico, cod_colegiado, cod_minsalud, usuario_reg, fecha_reg, usuario_mod, activo,es_pool, clasificacion_medico, rif, archivo_firma_nombre_orig, archivo_firma_nombre,archivo_firma_tamano,archivo_firma_tipo, archivo_sello_nombre_orig,archivo_sello_nombre,archivo_sello_tamano,archivo_sello_tipo,cupos_aps)
select t.medico, t.cod_colegiado, t.cod_minsalud, t.usuario_reg, t.fecha_reg, t.usuario_mod, t.activo,t.es_pool, t.clasificacion_medico, t.rif, t.archivo_firma_nombre_orig, t.archivo_firma_nombre,t.archivo_firma_tamano,t.archivo_firma_tipo, t.archivo_sello_nombre_orig,t.archivo_sello_nombre,t.archivo_sello_tamano,t.archivo_sello_tipo,t.cupos_aps from medicos t
left join medico x on t.medico = x.medico where x.medico is null;' tmp_sanos_test
psql -h localhost -U $RESTAURA_USER -c'insert into medico_especialidad (medico, especialidad, minutos_atencion, activo, usuario_reg,fecha_reg, usuario_mod, fecha_mod, minutos_atencion_sucesiva,articulo_cita_ce_primera, articulo_cita_ce_sucesiva, es_plantilla_cita_p,plantilla_cita_p, es_plantilla_cita_s, plantilla_cita_s, es_plantilla_cita_pa,plantilla_cita_pa)
select medico, especialidad, minutos_atencion, activo, usuario_reg,fecha_reg, usuario_mod, fecha_mod, minutos_atencion_sucesiva,articulo_cita_ce_primera, articulo_cita_ce_sucesiva, es_plantilla_cita_p,plantilla_cita_p, es_plantilla_cita_s, plantilla_cita_s, es_plantilla_cita_pa,plantilla_cita_pa from medicoespec;' tmp_sanos_test
psql -h localhost -U $RESTAURA_USER -c 'insert into horario_medico(horario_medico, ambulatorio, medico, especialidad, tipo_consulta, thorario, dia, hora_desde, hora_hasta, fecha_desde, fecha_hasta, activo, usuario_reg, fecha_reg, usuario_mod, fecha_mod, cuarto, es_privado, horario_medico_anterior, es_primera_sucesiva)
select t.horario_medico, t.ambulatorio, t.medico, t.especialidad, t.tipo_consulta, t.thorario, t.dia, t.hora_desde, t.hora_hasta, t.fecha_desde, t.fecha_hasta, t.activo, t.usuario_reg, t.fecha_reg, t.usuario_mod, t.fecha_mod, t.cuarto, t.es_privado, t.horario_medico_anterior, t.es_primera_sucesiva from horariomed t
left join horario_medico x on t.horario_medico = x.horario_medico where x.horario_medico is null;' tmp_sanos_test
pg_dump -h localhost -U $RESTAURA_USER -a -t xfm_sgd_rol_usuario sanos_test |psql -h localhost -U $RESTAURA_USER tmp_sanos_test
pg_dump -h localhost -U $RESTAURA_USER -a -t xfm_sgd_rol_proceso sanos_test |psql -h localhost -U $RESTAURA_USER tmp_sanos_test
pg_dump -h localhost -U $RESTAURA_USER -a -t xfm_sgd_proceso_accion sanos_test |psql -h localhost -U $RESTAURA_USER tmp_sanos_test
pg_dump -h localhost -U $RESTAURA_USER -a -t xfm_sgd_log_proceso sanos_test |psql -h localhost -U $RESTAURA_USER tmp_sanos_test
pg_dump -h localhost -U $RESTAURA_USER -a -t xfm_sgd_rol_rol sanos_test |psql -h localhost -U $RESTAURA_USER tmp_sanos_test
echo "Actualizando ambulatorio y xfm_gen_parametro ... \n"
psql -h localhost -U $RESTAURA_USER -c "UPDATE ambulatorio SET base_datos_id='BDNCE' WHERE ambulatorio='d89511dc-7e4d-11e5-99d6-005056ad6a06';UPDATE ambulatorio SET base_datos_id='CDHCE' WHERE ambulatorio='6c733f6c-98b5-11e3-bc9a-00155d011f05';update xfm_gen_parametro set valor_cadena='reporte_calidad' where  id= 'sanos_erp_prm1';update xfm_gen_parametro set valor_cadena='Inicio2019' where id= 'sanos_erp_prm2';update xfm_gen_parametro set valor_cadena='CDHCE' where id= 'sanos_erp_bd';" tmp_sanos_test
psql -h localhost -U $RESTAURA_USER -c "UPDATE xfm_gen_parametro SET valor_cadena='reporte_calidad' WHERE  id= 'sanos_erp_prm1';UPDATE xfm_gen_parametro SET valor_cadena='Inicio2019' WHERE id='sanos_erp_prm2';UPDATE xfm_gen_parametro SET valor_cadena='CDHCE' WHERE id= 'sanos_erp_bd';" tmp_sanos_test
echo "Actualizando contraseña del usuario calidad ... \n"
psql -h localhost -U $RESTAURA_USER -c "UPDATE xfm_sgd_usuario SET clave = md5('1'), activo=1, bloqueado=0,intentos=0;" tmp_sanos_test
#psql -h localhost -U $RESTAURA_USER -c "update xfm_sgd_usuario set clave = usuarios.clave from usuarios where usuarios.id = xfm_sgd_usuario.id and usuarios.login = 'calidad'" tmp_sanos_test
echo "Otorgando permisos ... \n"
PERMISOS="lista_usuarios"
while IFS='' read -r LINEA || [[ -n "$LINEA" ]]; do
    echo "... a : $LINEA"
    psql -h localhost -U $RESTAURA_USER  -c "SELECT public.asignar_permisos('$LINEA');" tmp_sanos_test
done < "$PERMISOS"
echo "Borrando tabla temporales en ambas base de datos ... \n"
psql -h localhost -U $RESTAURA_USER -c 'drop table usuariosamb' sanos_test
psql -h localhost -U $RESTAURA_USER -c 'drop table usuariosamb' tmp_sanos_test
psql -h localhost -U $RESTAURA_USER -c 'drop table usuarios' sanos_test
psql -h localhost -U $RESTAURA_USER -c 'drop table usuarios' tmp_sanos_test
psql -h localhost -U $RESTAURA_USER -c 'drop table medicos' sanos_test
psql -h localhost -U $RESTAURA_USER -c 'drop table medicos' tmp_sanos_test
psql -h localhost -U $RESTAURA_USER -c 'drop table medicoespec' sanos_test
psql -h localhost -U $RESTAURA_USER -c 'drop table medicoespec' tmp_sanos_test
psql -h localhost -U $RESTAURA_USER -c 'drop table horariomed' sanos_test
psql -h localhost -U $RESTAURA_USER -c 'drop table horariomed' tmp_sanos_test
