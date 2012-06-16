use uv
import uv

main: func {
    loop := Loop default()
    dns := loop dns()

    host := "www.perdu.com"
    port := 80

    dns lookup(host, |status, result|
        log("DNS lookup (status %d): %s resolves to %s", status, host, result address in _)
        tcp := loop tcp()
        port // FIXME: rock workaround

        target := result address in withPort(port)
        tcp connect(target, |status, stream|
            log("Connected to %s:%d (status %d)", target _, port, status)
            stream write("GET / HTTP/1.1\n")
            stream write("Host: %s:%d\n" format(host, port))
            stream write("Connection: close\n")
            stream write("\n")
            log("Sent request. Response: ")
            stream readStart(|nread, buf|
                buf _ print()
            )
        )
    )

    loop run()
    log("Program ended.")
}

log: func ~nofmt (s: String) {
    "[log] %s" printfln(s)
}

log: func (s: String, args: ...) {
    "[log] %s" printfln(s format(args))
}

