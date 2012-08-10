use uv
import uv

main: func {
    loop := Loop default()
    ip := loop ip()
    tcp := loop tcp()

    addr := ip v4("0.0.0.0", 3000)
    tcp bind(addr)

    tcp listen(SOMAXCONN, |status, server, client|
	log("Listening on %s:%d (status %d)", addr _, addr port, status)
	server readStart(|nread, buf|
	   buf _ print() 
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

