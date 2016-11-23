//Contar el número de eventos de un estado que se envía como parámetro en el año 2013
//Se podría modificar para que el año fuese también un parámetro, pero de momento este procedimientos será sólo para el año 2013
import org.voltdb.*;

public class eventosEstado2013 extends voltProcedure {

	public final SQLStmt numero_estado = new SQLStmt (
		"SELECT COUNT(*)"
		+ "FROM local_event AS LOCAL JOIN nws_event AS NWS"
		+ "ON LOCAL.id = NWS.id"
		+ "JOIN states AS S"
		+ "ON S.state_num = LOCAL.state_num"
		+ "WHERE (NWS.starttime > '2013-01-01' AND NWS.endtime < '2013-12-31' AND S.state_num = ?);"
		);

	public VolTable[] run(String estado)
		throws VoltAbortException {
			voltQueueSQL(numero_estado,estado);
			return voltExecuteSQL();
		}
}
