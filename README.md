
Tentative bindings for libuv.

Nothing is definitive, don't rely on it, it *will* blow up your dog.

## Getting uv

Clone <https://github.com/joyent/libuv/> somewhere, and from its directory, run:

    git archive HEAD --prefix='uv/' | (cd path/to/ooc-uv ; tar xf -)

Then go in `uv/` and hit `make` so you get a nice `uv/uv.a`

That's about it!

