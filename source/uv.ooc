use uv
include uv

Loop: cover from uv_loop_t* {
   
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
    
}

DNS: class {

    loop: Loop

    init: func (=loop) {}

    /**
     * Asynchronous DNS lookup
     */
    lookup: func (node: String, callback: Func(Int, AddrInfo)) -> Int {
        handle := gc_malloc(GetAddrInfo_t size) as GetAddrInfo 
        uv_getaddrinfo(loop, handle, _lookup_cb, node toCString(), null, null)
    }

    // private

    _lookup_cb: static func (handle: GetAddrInfo, status: Int, res: AddrInfo) {
        "Done lookup with status %d, yay!" printfln(status)
    }

}

AddrInfo: cover from AddrInfo_t* {
    address: SockAddr { get { this@ ai_addr } }
}

AddrInfo_t: cover from struct addrinfo {
    ai_addr: extern SockAddr
}

SockAddr: cover from SockAddr_t* {
    _: String { get {
        name := gc_malloc(40) as CString
        uv_ip4_name(this as SockAddrIn_t*, name, 1024)
        String new(name)
    } }
}

SockAddr_t: cover from struct sockaddr
SockAddrIn_t: cover from struct sockaddr_in

// private

GetAddrInfo: cover from GetAddrInfo_t*
GetAddrInfo_t: cover from uv_getaddrinfo_t

// these shouldn't be needed with rock's header parser, but meh.

uv_getaddrinfo: extern func (...) -> Int
uv_ip4_name: extern func (...) -> Int

