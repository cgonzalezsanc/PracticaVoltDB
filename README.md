# PracticaVoltDB

Para inicializar la base de datos y arrancar el schema, en primer lugar modificamos la variable $PATH, con el siguiente comando (se debe realizar en cada shell abierta):

export PATH=/opt/voltdb/bin:$PATH


Para compilar y ejecutar los fihceros '.java', necesitamos cargarlo en la BBDD y despues declararlo en el DDL de la misma forma que los procedimientos almacenados. Para compilarlo, usaremos el compilador "javac" utilizando el siguiente comando:

javac -cp "$CLASSPATH:/opt/voltdb/voltdb/*" UpdatePeople.java

Una vez esté compilado el código como si se tratase de una clase Java, necesitamos envolverlo en una fichero "jar" y cargarlo en la bbdd.

Por ejemplo, podemos meter la clase java creada con el anterior comando en un fichero jar llamado storedprocs.jar, de la manera siguiente:

jar cvf storedprocs.jar *.class

Una vez que está metido en un fichero '.jar' lo podemos cargar en la base de datos usando los siguientes comandos:

sqlcmd
load classes storedprocs.jar

Añadimos este comando al schema y realizamos lo siguiente:

CREATE PROCEDURE
PARTITION ON TABLE people COLUMN state_num
FROM CLASS UpdatePeople;

Ahora que tenemos un procedimiento almacenado Java y actualizado el schema, estamos preparados para probar su funcionamiento. Obviamente, no queremos invocar nuestro nuevo procedimiento manualmente para cada registro en la tabla "People". Podemos escribir un programa que lo realice por nosotros. Afortunadamente, existe un programa que está disponible y que podemos usar.

El comando "csvloader" usa por defecto el "INSERT" en los procedimientos para cargar los datos en la tabla. De todas maneras, podemos especificar diferentes procedimientos si queremos. Así que podemos usar el comando "csvloader" para invocar nuestros procedimientos para actualizar la base de datos con cada registro en el fichero de datos.

## Aplicaciones de cliente
Ahora tenemos un ejemplo de base de datos funcional. Hemos incluido incluso un procedimiento almacenado para actualizar los datos de la BBDD. Para ejecutar los procedimientos almacenados utilizamosla utilizadad de cvsloader preexistente.
La mayoría de las aplicaciones requieren más de un procedimiento almacenado. Entendiendo como integrar las llamadas a la base de datos en la aplicación del cliente es la clave para producir una solución de negocios completa.

VoltDB proporciona librerías de cliente en varios lenguajes de programación, cada uno con su propia sintaxis única, tipos de datos soportados, y capacidades. De todas masneras, el proceso general para llamar a VoltDB desde las aplicaciones de cliente es el mismo en todos los lenguajes de programación:
	1.- Crear la conexión del cliente con la base de datos.
	2.- Hacer una o más llamadas a los procedimientos almacenados e interpretar los resultados.
	3.- Cerrar la conexión cuando estemos preparados.

##Diseñando procedimientos almacenados para el acceso a datos
Teniendo definido el esquema, podemos ahora definir los procedimientos almacenados que las aplicaciones de cliente necesitan. La primera aplicacion, que carga las alertas del clima, necesitan dos procedimientos almacenados:
	1.- FindAlert: Para determinar si una alerta dada ya está almacenada en la base de datos. Este primer procedimiento almacenado es una simple consulta SQL basada en la columna "id" y puede ser definido en el schema.
	2.- LoadAlert: Para insertar la información en las dos tablas "nws_alert" y "local_alert". Este segundo procedimiento almacenado necesita la creación de un registro en la tabla replicada "nws_alert" y luego, tantos registros como "local_alert" necesite. Adicionalmente, el fichero de entrada de datos lista el "state" y los "Cunty FIPS numbers" como una cadena de caracteres de seis dígitos separados por especios.

Como resultado de los anterior, el segundo procedimiento almacenado ha de ser escrito en Java para que se puedan encolar múltiples consultas y descifrar os valores de entrada antes de usarlos como argumentos de la consulta. Podemos ver todo esto en el fichero "LoadAlert.java".

Despues de escribir los procedimientos almacenados y de crear el fichero schema adicional, podemos compilar los procedimientos almacenados Java, empaquetar ambos junto con el fichero "UpdatePeople" que hemos creado anteriormente en un fichero ".jar" y argar ambos procedimientos y el schema en la base de datos. 
Primero debemos cargar los procedimientos almacenados, de forma que la base de datos pueda encontrar el fichero "class" cuando procese el "CREATE PROCEDURE FROM CLASS" en el schema. Para ésto, será encesario escribir el siguiente código:

javac -cp "$CLASSPATH:/opt/voltdb/voltdb/*" LoadAlert.java
jar cvf storedprocs.jar *.class
sqlcmd
load classes storedprocs.jar;
file weather.sql;

## Creando la aplicación del cliente "LoadWeather"
El objetivo de la primera aplicación de cliente, "LoadWeather", es leer las aletas climatológicas del National Weather Service y cargarlos en la base de datos. La lógica del programa básico es:
	1.- Leer y analizar el fichero fuente de alertas de NWS.
	2.- Para cada alerta, primero comprueba si ya existe en la base de datos usando el procedimiento "FindAlert".
		2.1.- Si existe, sigue adelante con la siguiente.
		2.2.- Si no existe, inserta la alerta usando el procedimiento "LoadAlert".
Como esta aplicación se ejecuta periódicamente, podemos escribirlo en un lenguaje de programación que permita el análisis de XML y que se pueda ejecutar desde la línea de comandos. Python es el lenguaje de programación adecuado ya que reúne todos los requerimientos.

La primera tarea de la aplicación de cliente es incluir todas las librerías necesarias. En este caso, dado que vamos a utilizar Python, necesitamos incluir las librerías Python de VoltDB para entradas/salidas y análisis de XML. El principio del programa Python es el siguiente:

import sys
from xml.dom.minidom import parseString
from voltdbclient import *

El comienzo del programa contiene (como se puede ver en el código anterior) código para leer y analizar el XML de la entrada estándar y definir algunas funciones útiles. Se puede ver el código completo en el fichero "LoadWeather.py".

El primer paso para realizar una aplicación de cliente, como comentábamos al principio, es "Crear la conexión con el cliente". En Python, ésto se realiza con el siguiente código:

client = FastSerializer ("localhost", 21212)

Al usar Python, debemos declarar también cualquier procedimiento almacenado que pretendamos utilizar. En este caso, necesitamos declarar "Findalert" y "LoadAlert". Lo declaramos con el siguiente código:

finder = VoltProcedure( client, "FindAlert", [
FastSerializer.VOLTTYPE_STRING,
])
loader = VoltProcedure( client, "LoadAlert", [
FastSerializer.VOLTTYPE_STRING,
FastSerializer.VOLTTYPE_STRING,
FastSerializer.VOLTTYPE_STRING,
FastSerializer.VOLTTYPE_STRING,
FastSerializer.VOLTTYPE_STRING,
FastSerializer.VOLTTYPE_STRING,
FastSerializer.VOLTTYPE_STRING,
FastSerializer.VOLTTYPE_STRING
])

Este código es un conjunto de bucles que recorre cada alerta en la estructura del fichero XML comprobando si existe en la base de datos y en cao contrario, lo añade. 

El código para las llamadas a procedimientos almacenados de VoltDB es el siguiente (No es necesario escribirlo ya que está incluido en los ficheros):

response = finder.call([ id ])
if (response.tables):
	if (response.tables[0].tuples):
		cOld += 1
	else:
		response = loader.call([ id, wtype, severity, summary, starttime, endtime, updated, fips ])
		if (response.status == 1):
			cLoaded += 1

La llamada a la funcion "finder" se utiliza para comprobar si algún registro ha sido devuelto. Si ocurre ésto, la alerta ya existe en la base de datos y se pasa a la siguiente.En caso contrario, la llamada a la funcion "loader" se utiliza para verificar el estado de la llamada. Si el estado del registro es 1, entonces sabremos que la llamada ha sido exitosa y se ha añadido a la base de datos esa alerta.

El último paso, una vez que están procesadas todas las alertas, es cerrar la conexión del cliente con la base de datos, de la siguiente manera:

client.close()

##Ejecutando la aplicación de cliente "LoadWeather"

Como Python es un lenguaje de programación que puede ejecutar "scripts" directamente, no es necesario la compilación previa antes de ejecutarlos. Pero necesitamos indicar a Python dónde se encuentra las librerías necesarias como el cliente VoltDB. Simplemente se añade la localización de las librerías de cliente de VoltDB en la variable de entorno "PYTHONPATH", ejecutando el siguiente código:

export PYTHONPATH="$HOME/voltdb/lib/python/"

Una vez definida la variable de entorno PYTHONPATH, estamos listos para ejecutar la aplicacion "LoadWeather". Es necesario cargar los datos de alertas climatológicas en el fichero "LoadWeather.py" de la siguiente manera (el fichero donde están todos los datos de las alertas es: "alerts.xml"):

python LoadWeather.py < data/alerts.xml

Aunque también podemos añadirlo directamente de la página web de NWS:

curls https://alerts.weather.gov/cap/us.php?x=0 | python LoadWeather.py

##Creación de la aplicacion de cliente "GetWeather"
Actualmente, la base de datos contiene todos los datos climatológicos, por lo que queda escribir una aplicación que nos permite recuperar todas las alertas asociadas a una localización específica. La aplicación "GetWeather" consiste simplemente en una llamada al procedimiento almacenado "GetAlertsByLocation". 

##Ejecución de la aplicacion de cliente "GetWeather"
Esta aplicación utiliza Java como lenguaje de programación así que necesitamos incluir el ".jar" de VoltDB en la variable de entorno CLASSPATH:

export CLASSPATH ="$CLASSPATH:$HOME/voltdb/voltdb/*:$HOME/voltdb/lib/*:./"

Ahora podemos compilar y ejecutar la aplicación usando los comandos Java estandar:

javac GetWeather.java
java GetWeather

##CONCLUSIONES

El comportamiento del programa dependerá de muchos factores como por ejemplo, cómo esté estructurado el schema, cómo están particionadas las tablas y los procedimientos y cómo estén diseñadas las aplicaciones de cliente.  Cuando se está escribiendo las aplicaciones de cliente, las especificaciones varían para cada lenguaje de programación. El proceso básico es el siguiente: 
	1.- Crear la conexión con la base de datos.
	2.- Llamadas a los procedimientos almacenados e interpretar los resultados. Usar llamadas asíncronas donde se pueda maximizar el volumen de trabajo o información.
	3.- Cerrar la conexión cuando se haya terminado.

## Procedimientos almacenados "extra"

### estadosSeveridad

Procedimiento que devuelve el nombre de los estados que tengan la severidad que se pase como argumento del procedimiento. Será necesario realizar el procedimiento anterior para ejecutarlo, es decir, compilar el código con `javac`, envolverlo con `jar`, cargarlo con un `load classes` y añadirlo al schema mediante `CREATE PROCEDURE FROM CLASS estadosSeveridad`.

###eventosEstado2013

Procedimiento almacenado que devuelve el número de eventos de un estado que se le pasará como argumento al procedimiento. El procedimiento consiste en los siguiente:
Comparará el "id" de los eventos de las tablas "local_event" y "nws_event" mediante un JOIN, después realizamos otro JOIN con la tabla "states" y comparará el "state_num" de esta tabla con el "state_num" del resultado del JOIN anterior, condicionado a que los datos de las columnas "starttime" y "endtime" de la tabla "nws_event" cumplan las condiciones impuestas y que el numero de estado coincida con el pasado como parámetro al procedimiento.
Como se indica en el procedimiento, es posible mejorarlo haciendo que el año que queremos comprobar se pase como parámetro (Posible futura mejora).
