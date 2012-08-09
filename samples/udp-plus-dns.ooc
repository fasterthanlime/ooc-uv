use uv
import uv

main: func {
    loop := Loop default()
    dns := loop dns()

    dns lookup("localhost", |status, result|
	udp := loop udp()
	target := result address in withPort(1234)
	udp send("hello", target@)
    )

    loop run()
}
