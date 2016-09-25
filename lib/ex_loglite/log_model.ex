defmodule ExLogLite.LogModel do
  @moduledoc """
  Build log messages according to LogLite format, in binary.
  """

  @version 2

  @doc """
  Build a LogLite style message, return an iolist same as C structure.
  """
  def build_message(:connection, {pid, machine_name, exec_path}) do
    [
      << 0::32-little, 0::32 >>,
      << @version::32-little, 0::32 >>,
      << pid::64-little >>,
      build_binary_chars(machine_name, 32),
      build_binary_chars(exec_path, 260),
      << 0::size(28)-unit(8) >>
    ]
  end
  def build_message(typ, msg) do
    [ build_type_part(typ) | build_text_message_part(msg) ]
  end

  @doc """
  Build binary in the same format as char array in C from a string.
  Trim `str` if exceeds `max_len`, pad 0 if not long enough. Count in `byte_size`
  """
  def build_binary_chars(str, max_len) when byte_size(str) == max_len, do: << str::bytes >>
  def build_binary_chars(str, max_len) when byte_size(str) > max_len, do: << binary_part(str, 0, max_len)::bytes >>
  def build_binary_chars(str, max_len) do
    pad_len = max_len - byte_size(str)
    << str::bytes, 0::size(pad_len)-unit(8) >>
  end

  defp build_type_part(:simple), do: << 1::32-little, 0::32 >>
  defp build_type_part(:large), do: << 2::32-little, 0::32 >>
  defp build_type_part(:continuation), do: << 3::32-little, 0::32 >>
  defp build_type_part(:continuation_end), do: << 4::32-little, 0::32 >>

  defp build_text_message_part({timestamp, severity, module, channel, message}) do
    [
      << timestamp::64-little >>,
      << severity::32-little >>,
      build_binary_chars(module, 32),
      build_binary_chars(channel, 32),
      build_binary_chars(message, 256),
      << 0::32 >>
    ]
  end

end
