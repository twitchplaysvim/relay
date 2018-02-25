defmodule Relay.MessageHandler do
  @ctrl_l_keycode 37
  @shift_l_keycode 50
  @digits "0123456789" |> String.codepoints
  @lowercase "abcdefghijklmnopqrstuvwxyz" |> String.codepoints
  @uppercase "ABCDEFGHIJKLMNOPQRSTUVWXYZ" |> String.codepoints
  @special_chars "!\"$#%^&'()*-+=,.\\:;<>?@[]_`{}|~" |> String.codepoints
  @special_char_map %{
    "!" => "exclam",
    "\"" => "qoutedbl",
    "$" => "dollar",
    "#" => "numbersign",
    "%" => "percent",
    "^" => "asciicircum",
    "&" => "ampersand",
    "'" => "apostrophe",
    "(" => "parenleft",
    ")" => "parenright",
    "*" => "asterisk",
    "-" => "minus",
    "+" => "plus",
    "=" => "equal",
    "," => "comma",
    "." => "period",
    "\\" => "backslash",
    ":" => "colon",
    ";" => "semicolon",
    "<" => "less",
    ">" => "greater",
    "?" => "question",
    "@" => "at",
    "[" => "bracketleft",
    "]" => "bracketright",
    "_" => "underscore",
    "`" => "grave",
    "{" => "braceleft",
    "}" => "braceright",
    "|" => "bar",
    "~" => "asciitilde"
  }
  @multi_char_commands ["space", "esc", "backspace", "tab", "return", "slash", "ctrl+c", "ctrl+d"]
  @multi_char_command_map %{
    "space" => "space",
    "esc" => "Escape",
    "backspace" => "BackSpace",
    "tab" => "Tab",
    "return" => "Return",
    "slash" => "slash",
    "ctrl+c" => "#{@ctrl_l_keycode}+54",
    "ctrl+d" => "#{@ctrl_l_keycode}+40"
  }

  def handle_message(message) when message in @digits when message in @lowercase do
    emulate_key(message)
    :ok
  end

  def handle_message(message) when message in @uppercase do
    emulate_key("#{@shift_l_keycode}+#{message}")
    :ok
  end

  def handle_message(message) when message in @special_chars do
    key_code = @special_char_map[message]
    emulate_key(key_code)
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
    System.cmd("xdotool", ["key", key_code])
  end
end
