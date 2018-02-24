defmodule Relay.IrcClient do
  require Logger

  @irc_host "irc-ws.chat.twitch.tv"
  @irc_path "/irc"
  @username Application.get_env(:relay, :twitch_username)
  @oauth_token Application.get_env(:relay, :twitch_oauth_token)
  @target_channel Application.get_env(:relay, :twitch_target_channel)

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(_opts) do
    pid = spawn_link(__MODULE__, :init, [])
    {:ok, pid}
  end

  def init() do
    socket = Socket.Web.connect!(
      @irc_host,
      path: @irc_path,
      secure: true
    )

    # send!/1 doesn't return the socket, so we can't pipe
    socket |> Socket.Web.send!({:text, "CAP REQ :twitch.tv/tags twitch.tv/commands twitch.tv/membership"})
    socket |> Socket.Web.send!({:text, "PASS #{@oauth_token}"})
    socket |> Socket.Web.send!({:text, "NICK #{@username}"})
    socket |> Socket.Web.send!({:text, "JOIN #{@target_channel}"})

    Logger.info("Connected to #{@irc_host}#{@irc_path}")

    loop(socket)
  end

  defp loop(socket) do
    case handle_message(socket) do
      :ok ->
        loop(socket)
      :error ->
        Logger.error("Unexpected error, we're going down")
    end
  end

  defp handle_message(socket) do
    message = Socket.Web.recv!(socket)
    case message do
      {:close, _, _} ->
        Logger.error(inspect(message))
        Socket.Web.close(socket)
        :error
      {:text, text} ->
        handle_text(socket, text)
        :ok
      _ ->
        Logger.info(inspect(message))
        :ok
    end
  end

  defp handle_text(socket, text) do
    case text do
      "PING" <> ping_tail ->
        pong_response = "PONG#{ping_tail}"
        Logger.info("Responding to PING with: #{pong_response}")
        Socket.Web.send(socket, {:text, pong_response})

      message_text ->
        message_splits = String.split(message_text, "PRIVMSG #{@target_channel} :")
        case Enum.at(message_splits, 1) do
          nil ->
            :ok
          chat_message ->
            # drop trailing "\r\n"
            trimmed_message = String.trim(chat_message)
            Relay.MessageHandler.handle_message(trimmed_message)
        end
        :ok
    end
  end
end
