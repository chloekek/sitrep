module sitrep.receive.sinks.ømq;

import sitrep.receive.sinks.common : Sink, SinkFactory;

import ømq = sitrep.util.ømq;

final
class ØmqConnectedPushSink
    : Sink
{
private:
    ømq.Socket socket;

public:
    @safe
    this(ref shared(ømq.Context) context, scope const(char)[] endpoint) scope
    {
        this.socket = ømq.Socket(context, ømq.PUSH);
        this.socket.connect(endpoint);
    }

    @safe
    void put(scope const(ubyte)[] packet) scope
    {
        socket.send(packet, 0);
    }
}

/// Sink factory that creates new instances of ØmqConnectedPushSink
/// using a preconfigured ØMQ context and endpoint.
final
class ØmqConnectedPushSinkFactory
    : SinkFactory
{
private:
    shared(ømq.Context)* context;
    immutable(char)[] endpoint;

public:
    /// The ØMQ context is used for creating new sockets,
    /// and the endpoint is what they are connected to.
    nothrow pure @nogc @safe
    this(shared(ømq.Context)* context, immutable(char)[] endpoint) shared
    {
        this.context = context;
        this.endpoint = endpoint;
    }

    override @safe
    ØmqConnectedPushSink newSink() shared
    {
        return new ØmqConnectedPushSink(*context, endpoint);
    }
}
