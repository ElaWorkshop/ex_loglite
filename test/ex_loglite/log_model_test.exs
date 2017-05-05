defmodule ExLogLite.LogModelTest do
  use ExUnit.Case

  alias ExLogLite.LogModel

  test "`build_binary_chars` trim longer string" do
    assert LogModel.build_binary_chars("dfa", 2) == <<"df">>
  end

  test "`build_binary_chars` extend shorter string" do
    assert LogModel.build_binary_chars("dfa", 4) == <<"dfa", 0::8>>
  end

  test "`build_binary_chars` should handle unicode correctly" do
    assert LogModel.build_binary_chars("測試...", 1) == <<230>>

    assert LogModel.build_binary_chars("測試", 7) == << "測試", 0 >>
  end

  test "`build_message` for `:connection`" do
    raw_msg = LogModel.build_message(:connection, {12312, "dfa", "qqq"})

    assert is_list(raw_msg)

    bitstr = :erlang.list_to_bitstring(raw_msg)

    assert byte_size(bitstr) == 344
  end
end

defmodule ExLogLite.LogModeEQC do
  use ExUnit.Case
  use EQC.ExUnit

  alias ExLogLite.LogModel

  property "`build_binary_chars` always return string of a specific length" do
    forall {s, n} <- {utf8(), choose(1, 1000)} do
      ensure byte_size(LogModel.build_binary_chars(s, n)) == n
    end
  end
end
