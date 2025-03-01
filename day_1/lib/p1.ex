defmodule Part1 do
  def main do
    {left, right} = Utils.read_input(~c"lib/input")

    left = MergeSort.sort(left)
    right = MergeSort.sort(right)

    diffs = Enum.zip(left, right) |> Enum.map(fn {l, r} -> l - r end)
    total_diff = List.foldl(diffs, 0, fn diff, acc -> acc + abs(diff) end)

    IO.puts(["Answer: ", inspect(total_diff)])
  end
end
