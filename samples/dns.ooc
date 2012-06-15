use uv
import uv

main: func {
    loop := Loop default()
    dns := loop dns()

    dns lookup("joyent.com", |status, result|
        "Resolved address to %s" printfln(result address _)
        tcp := loop tcp()
        req := tcp connect(result address, |status, stream|
            "Connected, got stream %p" printfln(stream)
        )
    )

    loop run()
}

