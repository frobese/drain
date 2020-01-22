import Config

config :drain,
  processors: [
    Drain.Processor.Logger
  ],
  store: Drain.Store.Mnesia
