module sitrep.util.ømq;

import core.stdc.errno : EINTR, errno;
import std.exception : errnoEnforce;
import std.string : toStringz;

extern(C) nothrow private @nogc
{
    int zmq_close(void* socket);
    int zmq_connect(void* socket, const(char)* endpoint);
    int zmq_ctx_term(shared(void)*);
    int zmq_send(void* socket, const(void)* buf, size_t len, int flags);
    shared(void)* zmq_ctx_new();
    void* zmq_socket(shared(void)* context, int type);
}

enum PUSH = 8;

struct Context
{
private:
    shared(void)* context;

public:
    @disable this();
    @disable this(this);

    @trusted
    this(int n) shared
    {
        context = zmq_ctx_new();
        errnoEnforce(context !is null, "zmq_ctx_new");
    }

    @nogc @trusted
    ~this()
    {
        if (context !is null) {
        retry:
            const ok = zmq_ctx_term(context);
            if (ok == -1 && errno == EINTR)
                goto retry;
            context = null;
        }
    }
}

struct Socket
{
private:
    void* socket;

public:
    @disable this();
    @disable this(this);

    @trusted
    this(ref shared(Context) context, int type)
    {
        socket = zmq_socket(context.context, type);
        errnoEnforce(socket !is null, "zmq_socket");
    }

    @nogc @trusted
    ~this()
    {
        if (socket !is null) {
            zmq_close(socket);
            socket = null;
        }
    }

    @trusted
    void connect(scope const(char)[] endpoint) scope
    {
        const ok = zmq_connect(socket, endpoint.toStringz);
        errnoEnforce(ok != -1, "zmq_connect");
    }

    @trusted
    void send(scope const(ubyte[]) buf, int flags) scope
    {
    retry:
        const ok = zmq_send(socket, buf.ptr, buf.length, flags);
        if (ok == -1 && errno == EINTR)
            goto retry;
        errnoEnforce(ok != -1, "zmq_send");
    }
}
