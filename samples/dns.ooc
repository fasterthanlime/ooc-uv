use uv
import uv

main: func {
    loop := Loop default()
    dns := loop dns()

    host := "localhost"
    port := 8000

    dns lookup(host, |status, result|
        "DNS lookup (status %d): %s resolves to %s" printfln(status, host, result address in _)
        tcp := loop tcp()
        port // FIXME: rock workaround

        target := result address in withPort(port)
        tcp connect(target, |status, stream|
            "Connected to %s:%d (status %d): got stream %p" printfln(target _, port, status, stream)
            stream write("GET / HTTP/1.1\n")
            stream write("Host: %s:%d\n" format(host, port))
            stream write("\n")
            "Wrote HTTP GET request" println()
        )
    )

    loop run()
}

