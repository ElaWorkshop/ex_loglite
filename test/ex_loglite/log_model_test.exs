defmodule ExLoglite.LogModelTest do
  use ExUnit.Case

  alias ExLoglite.LogModel

  test "`build_binary_chars` trim longer string" do
    assert LogModel.build_binary_chars("dfa", 2) == <<"df">>
  end

  test "`build_binary_chars` extend shorter string" do
    assert LogModel.build_binary_chars("dfa", 4) == <<"dfa", 0::8>>
  end

  test "`build_message` for `:connection`" do
    raw_msg = LogModel.build_message(:connection, {12312, "dfa", "qqq"})

    assert is_list(raw_msg)

    bitstr = :erlang.list_to_bitstring(raw_msg)

    assert byte_size(bitstr) == 344
  end

end
