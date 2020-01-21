# Drain
Documentation is available on [hex.pm](https://hexdocs.pm/drain)

## Installation
The package can be installed by adding `drain` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:drain, "~> 1.0.0-alpha.0"}
  ]
end
```
And adding it to your configuration in `config.exs`:
```elixir
config :drain,
  aggregators: [
    Drain.Aggregator.Logger
  ],
  store: Drain.Store.Mnesia
```

## Copyright and License
 Copyright 2020 frobese GmbH

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.