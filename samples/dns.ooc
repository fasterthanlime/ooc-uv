use uv
import uv

main: func {
    loop := Loop default()
    dns := DNS new(loop)

    dns lookup("joyent.com", |status, result|
        "Resolved address to %s" printfln(result address _)
    )

    loop run()
}

