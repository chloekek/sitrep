module sitrep.receive.protocols.tcp;

import sitrep.receive.sinks.common : SinkFactory;
import std.range : put;

import bsd = sitrep.util.socket;
import ømq = sitrep.util.ømq;

/// State necessary for receiving packets over TCP.
///
/// This class implements the bsd.Server interface,
/// allowing it to handle clients.
/// The listen_and_serve method uses this implementation,
/// and this is the typical use case,
/// so you probably don’t have to call serve yourself.
final
class TcpReceiver
    : bsd.Server
{
private:
    shared(SinkFactory) sinks;

public:
    /// Create a new TCP receiver using
    /// all the state necessary for it.
    nothrow pure @nogc @safe
    this(shared(SinkFactory) sinks) shared
    {
        this.sinks = sinks;
    }

    /// Listen on a new TCP socket on the given address.
    /// Accept new clients and serve them in a new thread each.
    @safe
    void listen_and_serve(ushort port, uint host) shared
    {
        auto listen = bsd.Socket(bsd.AF_INET, bsd.SOCK_STREAM, bsd.IPPROTO_TCP);
        listen.setsockopt_socket_reuseaddr(true);
        listen.bind_in(port, host);
        listen.listen(128);
        for (;;)
            // TODO: Handle accept errors.
            listen.accept_spawn(this);
    }

    /// Serve a single connected client.
    /// Packets received from the client
    /// are forwarded to a sink
    /// created using the sink factory.
    ///
    /// This method is called by listen_and_serve,
    /// so you probably don’t have to call it yourself.
    override @safe
    void serve(bsd.Socket client) shared
    {
        scope sink = sinks.newSink();
        for (;;) {
            // TODO: Handle recv errors.
            const packet = client.recv_packet();
            put(sink, packet);
        }
    }
}

private @safe
ubyte[] recv_packet(ref scope bsd.Socket client)
{
    const len = client.recv_ushort();
    auto  packet = new ubyte[len];
    client.recv_exact(packet, 0);
    return packet;
}

private @safe
ushort recv_ushort(ref scope bsd.Socket client)
{
    ubyte[2] buf;
    client.recv_exact(buf, 0);
    return buf[0] | buf[1] << 8;
}
