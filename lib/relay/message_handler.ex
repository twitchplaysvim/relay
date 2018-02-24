defmodule Relay.MessageHandler do
  @digits "0123456789"
  @lowercase "abcdefghijklmnopqrstuvwxyz"
  @uppercase "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  @special "[];'\,./'`"
  @shift_special "!@£$%^&*()_+}{:\"|?><~"
  @alt_special "¡€#¢§ˆ¶¨ªº–≠‘“…æ«÷≥≤§±"
  @permitted_single_chars "#{@digits}#{@lowercase}#{@uppercase}#{@special}#{@shift_special}#{@alt_special}" |> String.codepoints
  @multi_char_commands ["esc", "backspace", "tab", "return"]
  @multi_char_command_map %{
    "esc" => "Escape",
    "backspace" => "BackSpace",
    "tab" => "Tab",
    "return" => "Return"
  }
  # @modifiers ["ctrl"] # i'm not sure how to tackle this yet

  def handle_message(message) when message in @permitted_single_chars do
    emulate_key(message)
    :ok
  end

  def handle_message(message) when message in @multi_char_commands do
    key_code = @multi_char_command_map[message]
    emulate_key(key_code)
    :ok
  end

  def handle_message(_message) do
    :discard
  end

  defp emulate_key(key_code) do
    System.cmd("xdotool", ["search", "--name", "twitchplaysvim", "key", key_code])
  end
end
