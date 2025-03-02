defmodule Main do
  def p1_ex do
    fp = "./lib/example"
    cheat_duration = 2
    solution = Utils.solve(fp, cheat_duration)

    target_savings = 1

    print_debug(solution)

    IO.puts([
      "\nAnswer: ",
      inspect(
        length(
          Enum.filter(solution.jumps, fn
            {_, _, s, e, dur} -> e - s - dur >= target_savings
          end)
        )
      )
    ])
  end

  def p1 do
    fp = "./lib/input"
    cheat_duration = 2
    solution = Utils.solve(fp, cheat_duration)

    target_savings = 100

    IO.puts([
      "\nAnswer: ",
      inspect(
        length(
          Enum.filter(solution.jumps, fn
            {_, _, s, e, dur} -> e - s - dur >= target_savings
          end)
        )
      )
    ])
  end

  def p2_ex do
    fp = "./lib/example"
    cheat_duration = 20
    solution = Utils.solve(fp, cheat_duration)
    print_debug(solution)

    target_savings = 50

    IO.puts([
      "\nAnswer: ",
      inspect(
        length(
          Enum.filter(solution.jumps, fn
            {_, _, s, e, dur} -> e - s - dur >= target_savings
          end)
        )
      )
    ])
  end

  def p2 do
    fp = "./lib/input"
    cheat_duration = 20
    solution = Utils.solve(fp, cheat_duration)

    target_savings = 100

    IO.puts([
      "\nAnswer: ",
      inspect(
        length(
          Enum.filter(solution.jumps, fn
            {_, _, s, e, dur} -> e - s - dur >= target_savings
          end)
        )
      )
    ])
  end

  defp print_debug(solution) do
    IO.puts("Path")

    print_grid(
      solution.row_count,
      solution.col_count,
      fn r, c ->
        link = Map.get(solution.links, {r, c})

        case link do
          nil -> "##"
          {dist, next_id} -> inspect(dist)
        end
      end,
      5
    )

    IO.puts("\nJumps (time saved, start, end)")

    solution.jumps
    |> Enum.sort(fn {_, _, a1, a2, a3}, {_, _, b1, b2, b3} -> a2 - a1 - a3 < b2 - b1 - b3 end)
    |> Enum.each(fn {tile_id, candidate_id, tile_dist, candidate_dist, duration} ->
      score = candidate_dist - tile_dist - duration
      IO.inspect({score, tile_dist, candidate_dist})
    end)
  end

  defp print_grid(h, w, fun, pad \\ 3) do
    0..(h - 1)
    |> Enum.each(fn r ->
      0..(w - 1)
      |> Enum.each(fn c ->
        text = fun.(r, c)
        IO.write(String.pad_leading(text, pad))
      end)

      IO.write("\n")
    end)
  end
end
