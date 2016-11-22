import org.voltdb.*;

public class estadosSeveridad extends VoltProcedure {

  public final SQLStmt consigueEstado = new SQLStmt(
      " SELECT DISTINCT states.name "
    + " FROM local_event"
    + " JOIN nws_event"
    + " ON local_event.id = nws_event.id"
	+ " JOIN states"
	+ " ON local_event.state_num=states.state_num"
	+ " WHERE nws_event.severity LIKE ?;");

  public VoltTable[] run(string severidad)
      throws VoltAbortException {

          voltQueueSQL( estadosSeveridad, severidad );
          return voltExecuteSQL();

      }
}
