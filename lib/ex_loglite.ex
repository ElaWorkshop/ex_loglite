defmodule ExLoglite do
  @moduledoc false

  use GenEvent

  alias ExLoglite.LogModel

  @port 0xCC9

  def init(_) do
    # open connection
    {:ok, socket} = :gen_tcp.connect({127, 0, 0, 1}, @port, [:binary, {:packet, 0}])

    # send ConnectionMessage
    {:ok, hostname} = :inet.gethostname()
    machine_name = to_string(hostname)
    :gen_tcp.send(socket, LogModel.build_message(:connection, {0xE1A, machine_name, ""}))

    {:ok, %{socket: socket}}
  end

  def handle_event({_level, gl, {Logger, _, _, _}}, state)
  when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({lv, _gl, {Logger, msg, ts, md}}, %{socket: socket} = state) do
    if byte_size(msg) <= 255 do
      send_simple_msg(socket, lv, msg, ts, md)
    else
      send_large_msg(socket, lv, msg, ts, md)
    end

    {:ok, state}
  end

  def handle_event(_, state), do: {:ok, state}

  defp send_simple_msg(socket, lv, msg, ts, md) do
    log_msg = LogModel.build_message(
      :simple,
      {
        convert_timestamp(ts),
        level_to_severity(lv),
        get_loglite_module(md),
        get_loglite_channel(md),
        msg
      })

    :gen_tcp.send(socket, log_msg)
  end

  defp send_large_msg(socket, lv, msg, ts, md) do
    msg_parts = split_large_msg(msg)

    begin_send_multiparts(socket, lv, ts, md, msg_parts)
  end

  defp level_to_severity(:debug), do: 0
  defp level_to_severity(:info), do: 1
  defp level_to_severity(:warn), do: 2
  defp level_to_severity(:error), do: 3

  epoch = {{1970, 1, 1}, {0, 0, 0}}
  @epoch :calendar.datetime_to_gregorian_seconds(epoch)

  defp convert_timestamp({date, {h, m, s, ms}} = _timestamp) do
    {date, {h, m, s}}
    |> :calendar.datetime_to_gregorian_seconds
    |> Kernel.-(@epoch)
    |> Kernel.*(1000)
    |> Kernel.+(ms)
  end

  defp get_loglite_module(metadata) do
    metadata
    |> Keyword.get(:application)
    |> to_string()
  end

  defp get_loglite_channel(metadata) do
    metadata
    |> Keyword.get(:module)
    |> to_string()
  end

  defp split_large_msg(msg), do: divide_bytes(msg, 255, []) |> Enum.reverse

  defp divide_bytes(bytes, div_len, acc) when byte_size(bytes) < div_len do
    [bytes | acc]
  end
  defp divide_bytes(bytes, div_len, acc) do
    size = byte_size(bytes)
    this_part = binary_part(bytes, 0, div_len)
    left_bytes = binary_part(bytes, div_len, size - div_len)

    divide_bytes(left_bytes, div_len, [this_part | acc])
  end

  defp begin_send_multiparts(socket, lv, ts, md, [first_part | msg_parts]) do
    first_msg = LogModel.build_message(
      :large,
      {
        convert_timestamp(ts),
        level_to_severity(lv),
        get_loglite_module(md),
        get_loglite_channel(md),
        first_part
      }
    )

    :gen_tcp.send(socket, first_msg)

    send_multiparts_cont(socket, lv, ts, md, msg_parts)
  end

  defp send_multiparts_cont(socket, lv, ts, md, [last_part]) do
    last_msg = LogModel.build_message(
      :continuation_end,
      {
        convert_timestamp(ts),
        level_to_severity(lv),
        get_loglite_module(md),
        get_loglite_channel(md),
        last_part
      }
    )

    :gen_tcp.send(socket, last_msg)
  end
  defp send_multiparts_cont(socket, lv, ts, md, [this_part | msg_parts]) do
    this_msg = LogModel.build_message(
      :continuation,
      {
        convert_timestamp(ts),
        level_to_severity(lv),
        get_loglite_module(md),
        get_loglite_channel(md),
        this_part
      }
    )

    :gen_tcp.send(socket, this_msg)

    send_multiparts_cont(socket, lv, ts, md, msg_parts)
  end

end
