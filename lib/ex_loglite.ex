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

    {:ok, socket}
  end

  def handle_event({_level, gl, {Logger, _, _, _}}, state)
  when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({level, _gl, {Logger, msg, ts, metadata}}, state) do
    require IEx
    IEx.pry


  end

  def handle_event(_, state), do: {:ok, state}

  epoch = {{1970, 1, 1}, {0, 0, 0}}
  @epoch :calendar.datetime_to_gregorian_seconds(epoch)

  defp convert_timestamp({date, {h, m, s, ms}}) do
    {date, {h, m, s}}
    |> :calendar.datetime_to_gregorian_seconds
    |> Kernel.-(@epoch)
    |> Kernel.*(1000)
    |> Kernel.+(ms)
  end

end
