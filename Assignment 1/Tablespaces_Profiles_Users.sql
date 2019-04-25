
/** PUNTO 2 **/
--Create 3 Tablespaces:
--First one with 3Gb and 1 datafile, the name of the tablespace should be "coordinadora"
CREATE TABLESPACE coordinadora 
DATAFILE 'datafile_coordinadora' SIZE 3G;

--Undo tablespace with 100Mb and 1 datafile (Set this tablespace to be used in the system)
CREATE UNDO TABLESPACE  undo_coordinadora 
DATAFILE 'datafile_undo_coordinadora' SIZE 100M;
ALTER SYSTEM SET UNDO_TABLESPACE = undo_coordinadora;

--Bigfile tablespace of 4Gb
CREATE BIGFILE TABLESPACE  bigfile_coordinadora 
DATAFILE 'datafile_bigfile_coordinadora' SIZE 4G;


/** PUNTO 3 **/
--Create an user with the username amartinezg.
--The user should be assigned to the tablespace.
--There are no restrictions of space for this user.
--The role of the user should be dba
--The user should be able to connect to the system


CREATE USER amartinezg
IDENTIFIED BY amartinezg
DEFAULT TABLESPACE coordinadora
QUOTA UNLIMITED ON coordinadora;
GRANT dba to amartinezg;


/** PUNTO 4 **/
--Create 3 profiles:
--Profile 1: clerk with a password life of 40 days, one session per user, 15 minutes of idle, 3 failed login attempts.
CREATE PROFILE clerk LIMIT
PASSWORD_LIFE_TIME 40
SESSIONS_PER_USER 1
IDLE_TIME  15
FAILED_LOGIN_ATTEMPTS 3;

--Profile 2: development with a password life of 100 days, two sessions per user, 30 minutes of idle and no failed login attempts.
CREATE PROFILE development LIMIT
PASSWORD_LIFE_TIME 100
SESSIONS_PER_USER 2
IDLE_TIME  30
FAILED_LOGIN_ATTEMPTS UNLIMITED;

--Profile 3: operative with a password life of 30 days, one session per user, 5 minutes of idle, 4 failed login attemps. 
--This profile can reuse the password after 30 days if the password has already been changed 3 times.
CREATE PROFILE operative LIMIT
PASSWORD_LIFE_TIME 30
SESSIONS_PER_USER 1
IDLE_TIME  5
FAILED_LOGIN_ATTEMPTS 4
PASSWORD_REUSE_TIME 30
PASSWORD_REUSE_MAX 3;

/** PUNTO 5 **/
--Create 3 users:
--You are free to pick the username
--One user should user the profile clerk, the second one development and the last one operative
--All of them should be able to connect to the database.
--The user with the profile operative should be locked.


CREATE USER usuario_coordinadora1
IDENTIFIED BY usuario_coordinadora1
DEFAULT TABLESPACE coordinadora
PROFILE clerk;

GRANT CONNECT TO usuario_coordinadora1;

CREATE USER usuario_coordinadora2
IDENTIFIED BY usuario_coordinadora2
DEFAULT TABLESPACE coordinadora
PROFILE development;

GRANT CONNECT TO usuario_coordinadora2;

CREATE USER usuario_coordinadora3
IDENTIFIED BY usuario_coordinadora3
DEFAULT TABLESPACE coordinadora
PROFILE operative;

GRANT CONNECT TO usuario_coordinadora3;

ALTER USER usuario_coordinadora3 ACCOUNT LOCK;

