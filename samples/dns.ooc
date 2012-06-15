use uv
import uv

main: func {
    loop := Loop default()
    dns := DNS new(loop)

    dns lookup("joyent.com", |number, addrinfo| "Lookup callback" println())

    loop run()
}

