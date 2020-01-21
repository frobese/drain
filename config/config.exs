import Config

config :drain,
  aggregators: [
    Drain.Aggregator.Logger
  ],
  store: Drain.Store.Mnesia
