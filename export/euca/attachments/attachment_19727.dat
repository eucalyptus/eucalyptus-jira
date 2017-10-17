import java.net.InetSocketAddress;
import java.net.Socket;
import java.util.concurrent.Executors
import org.apache.log4j.Logger
import org.jboss.netty.bootstrap.ConnectionlessBootstrap
import org.jboss.netty.buffer.ChannelBuffer
import org.jboss.netty.buffer.ChannelBuffers;
import org.jboss.netty.channel.ChannelHandlerContext
import org.jboss.netty.channel.ChannelPipeline
import org.jboss.netty.channel.ChannelPipelineFactory
import org.jboss.netty.channel.Channels
import org.jboss.netty.channel.ExceptionEvent
import org.jboss.netty.channel.FixedReceiveBufferSizePredictor
import org.jboss.netty.channel.MessageEvent
import org.jboss.netty.channel.SimpleChannelUpstreamHandler
import org.jboss.netty.channel.socket.DatagramChannelFactory
import org.jboss.netty.channel.socket.nio.NioDatagramChannelFactory
import org.xbill.DNS.Message
import org.xbill.DNS.Rcode
import com.eucalyptus.bootstrap.DNSBootstrapper;
import com.eucalyptus.cloud.ws.ConnectionHandler
import com.eucalyptus.cloud.ws.UDPHandler


/**
 * Quick Proof-of-Concept UDP DNS server using Netty.  
 * 
 * This script replaces the thread/socket based UDP server {@link UDPHandler} with a single-stage netty pipeline.  
 * The stage handler deals with consuming bytes coming up the pipeline and writing bytes down the pipeline with responses.
 * The responses are created in a way which is identical to the {@link UDPHandler} implementation.  
 * That is, a final static instance is kept in order to call the (should just as well be static) method 
 * {@link ConnectionHandler#generateReply(Message, byte[], int, Socket)}.
 * 
 * This handler based server differs from the current server in that:
 * <ol>
 * <li>No control thread: netty pipeline manages thread-work allocation</li>
 * <li>Handles UDP source/remote addresses: binding to any-address works right w/ colocated CC</li>
 * <li>Error handling:  unexpected errors in underlying DNS service, resolver, or library code can't kill the pipeline, so not the server either</li>
 * <li>Interface binding:  the server bootstrapper can bind to interfaces w/ InetSocketAddress </li>
 * </ol>
 * @see InetSocketAddress for binding to interfaces
 * @see #udpServer below for the closure which bootstraps the UDP socket and netty pipeline.
 * 
 */
class DnsHandler extends SimpleChannelUpstreamHandler {
  private static Logger LOG = Logger.getLogger( DnsHandler.class );
  private static final UDPHandler udp = new UDPHandler();
  @Override
  public void messageReceived(ChannelHandlerContext ctx, MessageEvent e) throws Exception {
    try {
      ChannelBuffer buffer = ((ChannelBuffer) e.getMessage());
      byte[] inbuf = new byte[buffer.readableBytes( )];
      buffer.getBytes( 0, inbuf );
      Message query = new Message(inbuf);
      ConnectionHandler.setRemoteInetAddress( e.getRemoteAddress( ).getAddress( ) );
      try {
        byte[] outbuf = udp.generateReply( query, inbuf, inbuf.length, null );
        ChannelBuffer chanOutBuf = ChannelBuffers.wrappedBuffer( outbuf );
        ctx.getChannel().write(chanOutBuf,e.getRemoteAddress( ));
        return;
      } catch ( Exception ex ) {
        LOG.debug( ex );
        byte[] outbuf = udp.errorMessage(query, Rcode.SERVFAIL);
        LOG.info(outbuf);
        ChannelBuffer chanOutBuf = ChannelBuffers.wrappedBuffer( outbuf );
        ctx.getChannel().write(chanOutBuf,e.getRemoteAddress( ));
        throw ex;
      } finally {
        ConnectionHandler.removeRemoteInetAddress( );
      }
    } catch ( Exception ex ) {
      LOG.debug( ex );
      byte[] outbuf = udp.formerrMessage(e.getMessage( ));
      LOG.info(outbuf);
      ChannelBuffer chanOutBuf = ChannelBuffers.wrappedBuffer( outbuf );
      ctx.getChannel().write(chanOutBuf,e.getRemoteAddress( ));
      throw ex;
    }
  }
  
  @Override
  public void exceptionCaught(ChannelHandlerContext ctx, ExceptionEvent e)
  throws Exception {
    e.getCause().printStackTrace();
    e.getChannel().close();
  }
}

/**
 * Create Netty UDP pipeline with DnsHandler attached.  
 * Handles bootstrapping the DNS socket and setting up the pipeline for the {@code DnsHandler}.
 * The contents of this closure are complimentary to the setup which occurs in {@link DNSBootstrapper#start()}, but are specific to UDP.
 * 
 * A similar (but not identical) TCP pipeline can be created.
 * 
 * @see DNSBootstrapper#start()
 * @see DNSBootstrapper#stop()
 */
def udpServer = {
  DatagramChannelFactory f = new NioDatagramChannelFactory(Executors.newCachedThreadPool());
  ConnectionlessBootstrap b = new ConnectionlessBootstrap(f);
  b.setPipelineFactory(new ChannelPipelineFactory() {
        public ChannelPipeline getPipeline() throws Exception {
          ChannelPipeline p = Channels.pipeline();
          p.addLast( "dns-server", new DnsHandler( ) );
          return p;
        }
      });
  //networkInterface
  b.setOption("tcpNoDelay", true);
  b.setOption("receiveBufferSize", 1048576);
  b.setOption("broadcast", "false");
  b.setOption("receiveBufferSizePredictor", new FixedReceiveBufferSizePredictor(1024));
  b.bind(new InetSocketAddress(53));
}
udpServer.run( );
