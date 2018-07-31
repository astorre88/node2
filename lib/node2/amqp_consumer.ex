defmodule Node2.AmqpConsumer do
  @moduledoc """
  RabbitMQ consumer process. Consumes rabbit queue messages,
  saves them to DB and send them to WS channel.
  """

  require Logger

  use GenServer
  use AMQP

  alias Node2.Chats

  def start_link do
    GenServer.start_link(__MODULE__, [], [])
  end

  @mq_url         Application.get_env(:amqp, :mq_url)
  @exchange       "node2_exchange"
  @queue          "node2_queue"
  @queue_error    "#{@queue}_error"
  @ws_topic       "telegram_source:lobby"
  @ws_command     "shout"
  @error_exchange "x-dead-letter-exchange"
  @error_key      "x-dead-letter-routing-key"

  def init(_opts) do
    rabbitmq_connect()
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
    spawn(fn -> consume(chan, tag, redelivered, payload) end)
    {:noreply, chan}
  end

  def handle_info({:DOWN, _, :process, _pid, _reason}, _) do
    {:ok, chan} = rabbitmq_connect()
    {:noreply, chan}
  end

  defp rabbitmq_connect do
    case Connection.open(@mq_url) do
      {:ok, conn} ->
        # Get notifications when the connection goes down
        Process.monitor(conn.pid)
        # Everything else remains the same
        {:ok, chan} = Channel.open(conn)
        setup_queue(chan)
        Basic.qos(chan, prefetch_count: 10)
        {:ok, _consumer_tag} = Basic.consume(chan, @queue)
        {:ok, chan}
  
      {:error, _} ->
        # Reconnection loop
        :timer.sleep(10_000)
        rabbitmq_connect()
    end
  end

  defp setup_queue(chan) do
    {:ok, _} = Queue.declare(chan, @queue_error, durable: true)

    # Messages that cannot be delivered to any consumer in the main queue will be routed to the error queue
    {:ok, _} =
      Queue.declare(
        chan,
        @queue,
        durable: true,
        arguments: [
          {@error_exchange, :longstr, ""},
          {@error_key, :longstr, @queue_error}
        ]
      )

    :ok = Exchange.fanout(chan, @exchange, durable: true)
    :ok = Queue.bind(chan, @queue, @exchange)
  end

  defp consume(channel, tag, redelivered, payload) do
    Chats.create_message(%{body: payload})
    Node2Web.Endpoint.broadcast(@ws_topic, @ws_command, %{body: payload})

    :ok = Basic.ack(channel, tag)
    Logger.log(:info, "Consumed a #{payload}.")
  end
end
