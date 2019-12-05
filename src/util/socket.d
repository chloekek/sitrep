module sitrep.util.socket;

public import core.sys.posix.netinet.in_ : AF_INET, IPPROTO_TCP, SOCK_STREAM;
public import core.sys.posix.netinet.in_ : INADDR_LOOPBACK;

import sitrep.util.thread : spawn;
import std.exception : basicExceptionCtors, enforce, errnoEnforce;

import arpa_inet = core.sys.posix.arpa.inet;
import netinet_in = core.sys.posix.netinet.in_;
import sys_socket = core.sys.posix.sys.socket;
import unistd = core.sys.posix.unistd;

struct Socket
{
private:
    int fd;

public:
    @disable this();
    @disable this(this);

    /// Create a socket from a file descriptor.
    nothrow pure @nogc @safe
    this(int fd) {
        this.fd = fd;
    }

    /// socket(2).
    @safe
    this(int domain, int type, int protocol) {
        fd = sys_socket.socket(domain, type, protocol);
        errnoEnforce(fd != -1, "socket");
    }

    /// close(2).
    @nogc @safe
    ~this()
    {
        if (fd != -1) {
            unistd.close(fd);
            fd = -1;
        }
    }

    private @trusted
    int accept_raw() scope
    {
        const client_fd = sys_socket.accept(fd, null, null);
        errnoEnforce(client_fd != -1, "accept");
        return client_fd;
    }

    /// accept(2).
    @safe
    Socket accept() scope
    {
        const client_fd = accept_raw();
        return Socket(client_fd);
    }

    /// Call accept, and then run the given server in a new thread.
    @trusted
    void accept_spawn(shared(Server) server) scope
    {
        immutable client_fd = accept_raw();
        spawn(delegate() { server.serve(Socket(client_fd)); });
    }

    /// bind(2) with sockaddr_in.
    @trusted
    void bind_in(ushort port, uint host) scope
    {
        const sys_port = arpa_inet.htons(port);
        const sys_host = arpa_inet.htonl(host);
        const addr_in = netinet_in.sockaddr_in(
            AF_INET, sys_port, netinet_in.in_addr(sys_host),
        );
        const addr = cast(const(netinet_in.sockaddr)*) &addr_in;
        const ok = sys_socket.bind(fd, addr, addr_in.sizeof);
        errnoEnforce(ok != -1, "bind");
    }

    /// listen(2).
    @safe
    void listen(int backlog) scope
    {
        const ok = sys_socket.listen(fd, backlog);
        errnoEnforce(ok != -1, "listen");
    }

    /// recv(2).
    @trusted
    size_t recv(scope ubyte[] buf, int flags) scope
    {
        const ok = sys_socket.recv(fd, buf.ptr, buf.length, flags);
        errnoEnforce(ok != -1, "recv");
        return ok;
    }

    /// Call recv repeatedly until the buffer is filled.
    @safe
    void recv_exact(scope ubyte[] buf, int flags) scope
    {
        while (buf.length) {
            const n = recv(buf, flags);
            enforce(n != 0, new RecvExactEofException());
            buf = buf[n .. $];
        }
    }

    /// setsockopt(2).
    @trusted
    void setsockopt_socket_reuseaddr(bool optval) scope
    {
        const(int) optval_int = optval;
        sys_socket.setsockopt(fd, sys_socket.SOL_SOCKET,
                              sys_socket.SO_REUSEADDR,
                              &optval_int, optval_int.sizeof);
    }
}

/// A server serves a single client.
///
/// Because servers can be passed to Socket.accept_spawn,
/// they must be shared.
interface Server
{
    @safe
    void serve(Socket client) shared;
}

/// Thrown when recv_exact cannot read enough bytes.
final
class RecvExactEofException
    : Exception
{
    nothrow pure @nogc @safe
    this(string file = __FILE__, size_t line = __LINE__)
    {
        super("Unexpected end of file", file, line);
    }
}
