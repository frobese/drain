# Phoenix Chat Example with federation over Drain

Ripped from https://github.com/dwyl/phoenix-chat-example.git

## Install the Dependencies

    mix setup

## Run the App

- Start a Drain server: `RUST_LOG=debug cargo run -- -a 0.0.0.0:6986 serve`
- Publish some messages: `RUST_LOG=debug cargo run -- -a 0.0.0.0:6986 pub chat/message '{"name":"foo","message":"hey!"}'`
- Check subscriptions: `RUST_LOG=debug cargo run -- -a 0.0.0.0:6986 sub 'chat/#'`
- Start a Chat server: `mix phx.server`
- Start another Chat server: `PORT=4444 mix phx.server`
