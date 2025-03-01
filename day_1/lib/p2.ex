defmodule Part2 do
  def main do
    {left, right} = Utils.read_input("lib/input")

    left = MergeSort.sort(left)
    right = MergeSort.sort(right)

    # Count occurences of target
    count = fn target, xs_sorted ->
      case xs_sorted do
        [] ->
          {0, []}

        [_ | _] ->
          {equal, not_equal} = Enum.split_while(xs_sorted, fn x -> x == target end)

          if length(equal) > 0 do
            IO.puts([inspect(target), " x", inspect(length(equal))])
          end

          {length(equal), not_equal}
      end
    end

    {vals, _} =
      List.foldl(left, {[], right}, fn target, {vals, rem} ->
        # Ensure that rem only contains values potentially equal to current or future targets
        # ie hd(rem) >= current_and_future_targets
        {_, rem} = Enum.split_while(rem, fn r -> r < target end)

        # Count occurences of target
        {c, rem} = count.(target, rem)
        {vals ++ [c * target], rem}
      end)

    total_val = List.foldl(vals, 0, fn v, acc -> acc + v end)

    IO.puts(["Answer: ", inspect(total_val)])
  end
end
