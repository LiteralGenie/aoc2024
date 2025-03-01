defmodule MergeSort do
  def sort(xs) do
    case xs do
      [] ->
        []

      [x] ->
        [x]

      _ ->
        # Split into halves
        {left, right} = Enum.split(xs, floor(length(xs) / 2))

        # Sort each half
        left = sort(left)
        right = sort(right)

        # Merge each half
        merge(left, right)
    end
  end

  defp merge(xs, ys) do
    case {xs, ys} do
      {[], []} ->
        []

      {xs, ys} ->
        {picked, xs, ys} = pick(xs, ys)
        [picked] ++ merge(xs, ys)
    end
  end

  defp pick(xs, ys) do
    case {xs, ys} do
      {[x | xtail], []} ->
        {x, xtail, []}

      {[], [y | ytail]} ->
        {y, [], ytail}

      {[x | xtail], [y | ytail]} ->
        if x < y do
          {x, xtail, ys}
        else
          {y, xs, ytail}
        end
    end
  end
end

# MergeSort.sort([1, 5, 3, 2]) |> IO.inspect(label: "result")

text = File.read!("./day_1/input")
# IO.puts(text)

{left, right} =
  String.split(text, "\n")
  |> List.foldl({[], []}, fn line, {left, right} ->
    [l, r] = String.split(line, ~r/\s+/, parts: 2)

    {
      [String.to_integer(l)] ++ left,
      [String.to_integer(r)] ++ right
    }
  end)

left = MergeSort.sort(left)
right = MergeSort.sort(right)

diffs = Enum.zip(left, right) |> Enum.map(fn {l, r} -> l - r end)
total_diff = List.foldl(diffs, 0, fn diff, acc -> acc + abs(diff) end)

IO.puts(["Answer: ", inspect(total_diff)])
