# Drain WIP

**TODOs:**

- [x] POC
- [x] Testbed
- [ ] Protocol
- [ ] Error handling
- [ ] Reconnects
- [ ] Discovery
- [ ] Documentation
- [ ] Tests

Native Elixir implementation using CBOR protocol over TCP.

Uses CBOR https://hex.pm/packages/cbor
$ socat tcp:localhost:6986 - |xxd

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `drain` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:drain, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/drain](https://hexdocs.pm/drain).

