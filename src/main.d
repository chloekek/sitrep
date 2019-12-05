module sitrep.main;

import sitrep.receive.protocols.tcp : TcpReceiver;
import sitrep.receive.sinks.ømq : ØmqConnectedPushSinkFactory;
import sitrep.util.socket : INADDR_LOOPBACK;
import std.stdio : writeln;

import ømq = sitrep.util.ømq;

@safe
void main()
{
    auto ømq_context  = new shared(ømq.Context)(0);
    auto sink_factory = new shared(ØmqConnectedPushSinkFactory)(ømq_context, "inproc://hello");
    auto tcp_receiver = new shared(TcpReceiver)(sink_factory);
    tcp_receiver.listen_and_serve(2435, INADDR_LOOPBACK);
}
