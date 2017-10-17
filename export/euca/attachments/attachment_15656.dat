import org.xbill.DNS.ARecord
import org.xbill.DNS.DClass
import org.xbill.DNS.Name
import org.xbill.DNS.Record
import com.eucalyptus.cloud.ws.ZoneManager
import com.eucalyptus.dns.ServiceZone
import com.eucalyptus.dns.TransientZone
import com.eucalyptus.dns.Zone
import com.eucalyptus.util.Internets

/**
 * All the zones which respond with the non-sense NS record
 */
[
  TransientZone.getExternalName( ),
  TransientZone.getInternalName( ),
  ServiceZone.getName( )
].collect{ Name zoneName ->
  /**
   * Get the zone
   */
  def zone = ZoneManager.getZone( zoneName );
  /**
   * Add an A record for each existing NS record
   */
  zone.NS.rrs.collect{ Record nsRecord ->
    def nsFixupARecord = new ARecord( nsRecord.getAdditionalName( ), DClass.IN, 60, Internets.localHostInetAddress( ) );
    zone.addRecord( nsFixupARecord );
  }
}
/**
 * Print outcome
 */
ZoneManager.zones.collect{ k, Zone v ->
  "\n${k}=>${v}\n"
}
