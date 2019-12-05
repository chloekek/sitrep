module sitrep.receive.sinks.common;

/// See src/receive/README for an overview.
interface Sink
{
    @safe
    void put(const(ubyte)[] packet);
}

/// Sink factories create sinks.
/// Usually all sinks created by a sink factory
/// write to the same underlying device or target,
/// but this is by no means mandatory.
///
/// Sink factories are shared between threads,
/// but sinks do not have to be thread-safe.
interface SinkFactory
{
    @safe
    Sink newSink() shared;
}
