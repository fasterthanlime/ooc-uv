use uv
include uv

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

Stream: cover from Stream_s*
Stream_s: cover from uv_stream_t extends Handle_s {

}

Req: cover from Req_s*
Req_s: cover from uv_req_t {
    data: extern Pointer
}

Connect: cover from Connect_s* 
Connect_s: cover from uv_connect_t extends Req_s {
    data: Pointer // FIXME: this should work from handle
    handle: extern Stream
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

   dns: func -> DNS { DNS new(this) }
   tcp: func -> TCP { TCP new(this) }
    
}

Loop_s: cover from uv_loop_t {
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

    connect: func (sockaddr: SockAddr, callback: Func(Int, Stream)) -> Int {
        // TODO: make new request, call uv_tcp_connect
        connect := gc_malloc(Connect_s size) as Connect
        connect@ data = wrap(callback as Func)
        uv_tcp_connect(connect, this, (sockaddr as SockAddrIn_s*)@, _connect_cb)
    }

    // private

    _connect_cb: static func (handle: Connect, status: Int) {
        callback := handle@ data as WrappedFunc
        f: Func(Int, Stream) = callback closure@
        f(status, handle@ handle)
    }

}

TCP_s: cover from uv_tcp_t extends Handle_s {
    
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
    _: String { get {
        name := gc_malloc(40) as CString
        uv_ip4_name(this as SockAddrIn_s*, name, 1024)
        String new(name)
    } }
}

SockAddr_s: cover from struct sockaddr
SockAddrIn_s: cover from struct sockaddr_in

// private

GetAddrInfo: cover from GetAddrInfo_s* extends Handle {
}

GetAddrInfo_s: cover from uv_getaddrinfo_t {
    data: Pointer // FIXME: this should work from handle
}

// these shouldn't be needed with rock's header parser, but meh.

// dns
uv_getaddrinfo: extern func (...) -> Int

// tcp
uv_tcp_init: extern func (...) -> Int
uv_tcp_connect: extern func (...) -> Int

uv_ip4_name: extern func (...) -> Int

