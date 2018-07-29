defmodule Node2.AmqpConsumer do
  require Logger
  use GenServer
  use AMQP

  alias Node2.Chats

  def start_link do
    GenServer.start_link(__MODULE__, [], [])
  end

  @mq_url      "amqp://guest:guest@localhost"
  @exchange    "node2_exchange"
  @queue       "node2_queue"
  @queue_error "#{@queue}_error"
  @ws_topic    "telegram_source:lobby"
  @ws_command  "shout"

  def init(_opts) do
    conn = try_connect()
    {:ok, chan} = Channel.open(conn)
    setup_queue(chan)

    # Limit unacknowledged messages to 10
    :ok = Basic.qos(chan, prefetch_count: 10)
    # Register the GenServer process as a consumer
    {:ok, _consumer_tag} = Basic.consume(chan, @queue)
    {:ok, chan}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: consumer_tag}}, chan) do
    {:noreply, chan}
  end

  # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, %{consumer_tag: consumer_tag}}, chan) do
    {:stop, :normal, chan}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, %{consumer_tag: consumer_tag}}, chan) do
    {:noreply, chan}
  end

  def handle_info({:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered}}, chan) do
    spawn fn -> consume(chan, tag, redelivered, payload) end
    {:noreply, chan}
  end

  defp try_connect do
    case Connection.open(@mq_url) do
      {:ok, conn} ->
        conn
      {:error, reason} ->
        Logger.log(:error, "failed for #{inspect reason}")
        :timer.sleep 5000
        try_connect()
    end
  end

  defp setup_queue(chan) do
    {:ok, _} = Queue.declare(chan, @queue_error, durable: true)
    # Messages that cannot be delivered to any consumer in the main queue will be routed to the error queue
    {:ok, _} = Queue.declare(chan, @queue,
                             durable: true,
                             arguments: [
                               {"x-dead-letter-exchange", :longstr, ""},
                               {"x-dead-letter-routing-key", :longstr, @queue_error}
                             ]
                            )
    :ok = Exchange.fanout(chan, @exchange, durable: true)
    :ok = Queue.bind(chan, @queue, @exchange)
  end

  defp consume(channel, tag, redelivered, payload) do
    Chats.create_message(%{body: payload})
    Node2Web.Endpoint.broadcast @ws_topic, @ws_command, %{body: payload}

    :ok = Basic.ack channel, tag
    Logger.log(:info, "Consumed a #{payload}.")
  end
end
