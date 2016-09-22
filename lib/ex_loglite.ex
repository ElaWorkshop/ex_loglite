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

  def handle_event({level, _gl, {Logger, msg, ts, metadata}}, %{socket: socket} = state) do
    log_msg = LogModel.build_message(
      :simple,
      {
        convert_timestamp(ts),
        level_to_severity(level),
        get_loglite_module(metadata),
        get_loglite_channel(metadata),
        msg
      })

    :gen_tcp.send(socket, log_msg)

    {:ok, state}
  end

  def handle_event(_, state), do: {:ok, state}

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

end
