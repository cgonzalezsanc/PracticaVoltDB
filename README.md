# PracticaVoltDB

Para inicializar la base de datos y arrancar el schema, en primer lugar modificamos la variable $PATH, con el siguiente comando (se debe realizar en cada shell abierta):
export PATH=/opt/voltdb/bin:$PATH


Para compilar y ejecutar los fihceros '.java', necesitamos cargarlo en la BBDD y despues declararlo en el DDL de la misma forma que los procedimientos almacenados. Para compilarlo, usaremos el compilador "javac" utilizando el siguiente comando:

javac -cp "$CLASSPATH:/opt/voltdb/voltdb/*" UpdatePeople.java

Una vez esté compilado el código como si se tratase de una clase Java, necesitamos envolverlo en una fichero "jar" y cargarlo en la bbdd.

Por ejemplo, podemos meter la clase java creada con el anterior comando en un fichero jar llamado storedprocs.jar, de la manera siguiente:

jar cvf stroedprocs.jar *.class

Una vez que está metido en un fichero '.jar' lo podemos cargar en la base de datos usando los siguientes comandos:

sqlcmd
load classes storedprocs.jar

Añadimos este comando al schema y realizamos lo siguiente:

CREATE PROCEDURE
PARTITION ON TABLE people COLUMN state_num
FROM CLASS UpdatePeople;



