use uv
import uv

main: func {
    loop := Loop default()
    ip := loop ip()
    udp := loop udp()

    udp send("hello", ip v4("127.0.0.1", 1234))

    loop run()
}
