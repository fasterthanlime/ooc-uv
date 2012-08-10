use uv
include uv, arpa/inet

/* general data structures */

Handle: cover from Handle_s* {
}

Handle_s: cover from uv_handle_t {
    /* read-only */
    loop: extern Loop_s*

    /* public */
    closeCallback: extern (close_cb) Pointer
    data: extern Pointer
}

Stream: cover from Stream_s* {

    /*
     * Queue an ooc string to be written
     */
    write: func ~str (str: String) -> Int {
        write(str toCString(), str size)
    }

    /**
     * Queue a buffer to be written
     */
    write: func (data: Char*, length: SizeT) -> Int {
        buf := (data, length) as Buf_t
        req := gc_malloc(Write_s size) as Write
        uv_write(req, this, buf&, 1, null)
    }

    /**
     * Read data from an incoming stream. The callback will be made several
     * several times until there is no more data to read or uv_read_stop is
     * called. When we've reached EOF nread will be set to -1 and the error is
     * set to UV_EOF. When nread == -1 the buf parameter might not point to a
     * valid buffer; in that case buf.len and buf.base are both set to 0.
     * Note that nread might also be 0, which does *not* indicate an error or
     * eof; it happens when libuv requested a buffer through the alloc callback
     * but then decided that it didn't need that buffer.
     */
    readStart: func (readCallback: Func (SSizeT, Buf_t)) -> Int {
        this@ data = wrap(readCallback as Func) // TODO: better idea?
        uv_read_start(this, _alloc_cb, _read_cb)
    }

    // private stuff

    _alloc_cb: static func (handle: Handle, suggestedSize: SizeT) -> Buf_t {
        (gc_malloc(suggestedSize), suggestedSize) as Buf_t
    }

    _read_cb: static func (handle: Stream, nread: SSizeT, buf: Buf_t) {
        callback := handle@ data as WrappedFunc
        f: Func(SSizeT, Buf_t) = callback closure@
        f(nread, buf)
    }

}

Stream_s: cover from uv_stream_t extends Handle_s {
    data: extern Pointer // shouldn't be needed
}

Req: cover from Req_s*
Req_s: cover from uv_req_t {
    data: extern Pointer
}

Write: cover from Write_s*
Write_s: cover from uv_write_t extends Req_s { }

UDPSend: cover from UDPSend_s*
UDPSend_s: cover from uv_udp_send_t extends Req_s { }

Connect: cover from Connect_s* 
Connect_s: cover from uv_connect_t extends Req_s {
    data: Pointer // FIXME: this should work from handle
    handle: extern Stream
}

Buf: cover from Buf_t*

Buf_t: cover from uv_buf_t {
    base: extern Char*
    len: extern SizeT

    _: String { get {
        String new(base, len)
    } }
}


/* loop */

Loop: cover from Loop_s* {
   
   /**
    * Returns the default loop.
    */ 
   default: extern(uv_default_loop) static func -> This

    /**
     * This function starts the event loop. It blocks until the reference count
     * of the loop drops to zero. Always returns zero.
     */
   run: extern(uv_run) func -> Int

   // all features are wrapped in classes:

   ip:  func -> IP { IP new(this) }
   dns: func -> DNS { DNS new(this) }
   tcp: func -> TCP { TCP new(this) }
   udp: func -> UDP { UDP new(this) }
    
}

Loop_s: cover from uv_loop_t {
}


IP: class {

    loop: Loop
    init: func (=loop)

    v4: func (ip: String, port: Int) -> SockAddrIn_s {
	uv_ip4_addr(ip, port)
    }

    v6: func (ip: String, port: Int) -> SockAddrIn6_s {
	uv_ip6_addr(ip, port)
    }

}

DNS: class {

    loop: Loop
    init: func (=loop)

    /**
     * Asynchronous DNS lookup
     */
    lookup: func (node: String, callback: Func(Int, AddrInfo)) -> Int {
        handle := gc_malloc(GetAddrInfo_s size) as GetAddrInfo 
        handle@ data = wrap(callback as Func)
        uv_getaddrinfo(loop, handle, _lookup_cb, node toCString(), null, null)
    }

    // private

    _lookup_cb: static func (handle: GetAddrInfo, status: Int, result: AddrInfo) {
        callback := handle@ data as WrappedFunc
        f: Func(Int, AddrInfo) = callback closure@
        f(status, result)
    }

}

TCP: cover from TCP_s* {

    new: static func (loop: Loop) -> This {
        tcp := gc_malloc(TCP_s size) as TCP_s*
        uv_tcp_init(loop, tcp)
        tcp
    }

    connect: func (sockaddr: SockAddrIn_s, callback: Func(Int, Stream)) -> Int {
        connect := gc_malloc(Connect_s size) as Connect
        connect@ data = wrap(callback as Func)
        uv_tcp_connect(connect, this, sockaddr, _connect_cb)
    }

    bind: func (sockaddr: SockAddrIn_s) -> Int {
	uv_tcp_bind(this, sockaddr)
    }

    listen: func (maxconns: Int, callback: Func (Int, Stream, Stream)) -> Int {
	this@ data = wrap(callback as Func)
	uv_listen(this, maxconns, _listen_cb)
    }

    // private

    _connect_cb: static func (handle: Connect, status: Int) {
        callback := handle@ data as WrappedFunc
        f: Func(Int, Stream) = callback closure@
        f(status, handle@ handle)
    }

    _listen_cb: static func (server: TCP, status: Int) {
	callback := server@ data
	f: Func(Int, Stream) = callback closure@

	client := server loop tcp()
	client@ data = server

	status = uv_accept(server, client)
	f(status, server, client)
    }

}

TCP_s: cover from uv_tcp_t extends Handle_s {
    
}

UDP: cover from UDP_s* {

    new: static func (loop: Loop) -> This {
	udp := gc_malloc(UDP_s size) as UDP_s*
	uv_udp_init(loop, udp)
	udp
    }

    send: func ~string (data: String, addr: SockAddrIn_s) -> Int {
	send(data toCString(), data size, addr)
    }

    send: func (data: Char*, length: SizeT, addr: SockAddrIn_s) -> Int {
	buf := (data, length) as Buf_t
	req := gc_malloc(UDPSend_s size) as UDPSend
	uv_udp_send(req, this, buf&, 1, addr, null)
    }

}

UDP_s: cover from uv_udp_t extends Handle_s {

}

// utils

WrappedFunc: class {
    closure: Closure*

    init: func (c: Closure) {
        closure = gc_malloc(Closure size)
        closure@ thunk = c thunk
        closure@ context = c context
    }
}

wrap: func (f: Func) -> WrappedFunc {
    WrappedFunc new(f as Closure)
}

AddrInfo: cover from AddrInfo_s* {
    address: SockAddr { get { this@ ai_addr } }
}

AddrInfo_s: cover from struct addrinfo {
    ai_addr: extern SockAddr
}

SockAddr: cover from SockAddr_s* {
    in: SockAddrIn { get {
        // TODO: check and throw exception
        this as SockAddrIn
    } }
}

SockAddr_s: cover from struct sockaddr

SockAddrIn: cover from SockAddrIn_s* {
    withPort: func (port: UShort) -> This {
        copy := gc_malloc(SockAddrIn_s size) as This
        memcpy(copy, this, SockAddrIn_s size)
        copy@ port = htons(port)
        copy
    }

    _: String { get {
        name := gc_malloc(100) as CString
        uv_ip4_name(this as SockAddrIn_s*, name, 1024)
        String new(name)
    } }
}

SockAddrIn_s: cover from struct sockaddr_in {
    port: extern(sin_port) UShort
}

SockAddrIn6_s: cover from struct sockaddr_in6 {
}

// private

GetAddrInfo: cover from GetAddrInfo_s* extends Handle {
}

GetAddrInfo_s: cover from uv_getaddrinfo_t {
    data: Pointer // FIXME: this should work from handle
}

// these shouldn't be needed with rock's header parser, but meh.

// arpa
htons: extern func (UShort) -> UShort

// stream
uv_write: extern func (...) -> Int
uv_read_start: extern func (...) -> Int

// dns
uv_getaddrinfo: extern func (...) -> Int

// tcp
uv_tcp_init: extern func (...) -> Int
uv_tcp_connect: extern func (...) -> Int
uv_tcp_bind: extern func (...) -> Int

SOMAXCONN: extern Int

// udp
uv_udp_init: extern func (...) -> Int
uv_udp_send: extern func (...) -> Int

// ip
uv_ip4_name: extern func (...) -> Int
uv_ip4_addr: extern func (ip: CString, ...) -> SockAddrIn_s
uv_ip6_addr: extern func (ip: CString, ...) -> SockAddrIn6_s

