defmodule Main do
  def p1e1() do
    regions = Solver.solve("./lib/example1")

    IO.puts([
      "Answer: ",
      inspect(Solver.score_regions(regions, fn r -> r.perimeter * r.area end))
    ])
  end

  def p1e2() do
    regions = Solver.solve("./lib/example2")

    IO.puts([
      "Answer: ",
      inspect(Solver.score_regions(regions, fn r -> r.perimeter * r.area end))
    ])
  end

  def p1e3() do
    regions = Solver.solve("./lib/example3")

    IO.puts([
      "Answer: ",
      inspect(Solver.score_regions(regions, fn r -> r.perimeter * r.area end))
    ])
  end

  def p1() do
    regions = Solver.solve("./lib/input")

    IO.puts([
      "Answer: ",
      inspect(Solver.score_regions(regions, fn r -> r.perimeter * r.area end))
    ])
  end

  def p2() do
    regions = Solver.solve("./lib/input")

    IO.puts([
      "Answer: ",
      inspect(Solver.score_regions(regions, fn r -> r.num_sides * r.area end))
    ])
  end
end

defmodule Solver do
  defmodule Region do
    @enforce_keys [:inside, :outside, :value, :area, :perimeter, :num_sides]
    defstruct [:inside, :outside, :value, :area, :perimeter, :num_sides]
  end

  def solve(fp) do
    grid = Utils.read_input(fp)
    # Debug.write_grid(grid, fn x -> x.value end)

    {_, regions} =
      grid.cells
      |> Map.keys()
      |> Enum.reduce(
        {MapSet.new(Map.keys(grid.cells)), []},
        fn xy, {unseen, regions} ->
          if not MapSet.member?(unseen, xy) do
            # No-op if already checked
            {unseen, regions}
          else
            # Otherwise calculate region
            {inside, outside, _} = flood(grid, xy, MapSet.new([xy]))

            area = MapSet.size(inside)
            perimeter = calc_perimeter(outside, inside)
            num_sides = count_sides(outside, inside)

            regions =
              regions ++
                [
                  %Region{
                    inside: inside,
                    outside: outside,
                    value: Utils.Grid.at(grid, xy).value,
                    area: area,
                    perimeter: perimeter,
                    num_sides: num_sides
                  }
                ]

            unseen = MapSet.difference(unseen, inside)

            {unseen, regions}
          end
        end
      )

    regions
  end

  # Calculate points inside / just outside boundary of region
  # Region is picked by provided start point
  #
  # Returns {
  #   inside: Set of (contiguous) points forming region
  #   outside: Set of points touching the region (in cardinal directions) but not inside the region
  # }
  defp flood(grid, start, inside, outside \\ MapSet.new(), seen \\ MapSet.new()) do
    {sx, sy} = start
    start_cell = Utils.Grid.at(grid, start)

    offsets = [
      {-1, 0},
      {1, 0},
      {0, -1},
      {0, 1}
    ]

    {inside, outside, seen} =
      offsets
      # Offset -> neighbor coord
      |> Enum.map(fn {ox, oy} -> {sx + ox, sy + oy} end)
      # For each neighbor...
      |> Enum.reduce(
        {inside, outside, seen},
        fn xy, {inside, outside, seen} ->
          cell = Utils.Grid.at(grid, xy)

          cond do
            # Cell already checked, no-op
            MapSet.member?(seen, xy) ->
              {inside, outside, seen}

            # Cell is OOB or not connected
            cell === nil or cell.value != start_cell.value ->
              seen = MapSet.put(seen, xy)
              outside = MapSet.put(outside, xy)
              {inside, outside, seen}

            # Cell is connected, recurse on its neighbors
            true ->
              seen = MapSet.put(seen, xy)
              inside = MapSet.put(inside, xy)
              flood(grid, xy, inside, outside, seen)
          end
        end
      )

    {inside, outside, seen}
  end

  defp calc_perimeter(outside, inside) do
    offsets = [
      {-1, 0},
      {1, 0},
      {0, -1},
      {0, 1}
    ]

    Enum.reduce(outside, 0, fn {x, y}, perim ->
      perim +
        length(
          offsets
          |> Enum.map(fn {ox, oy} -> {x + ox, y + oy} end)
          |> Enum.filter(fn xy -> MapSet.member?(inside, xy) end)
        )
    end)
  end

  defp count_sides(outside, inside) do
    offsets = [
      {-1, 0},
      {1, 0},
      {0, -1},
      {0, 1}
    ]

    # Interior points touching outside
    border_points =
      Enum.flat_map(outside, fn {x, y} ->
        Enum.map(offsets, fn {ox, oy} ->
          {x + ox, y + oy}
        end)
      end)
      |> Enum.filter(fn xy -> MapSet.member?(inside, xy) end)
      |> MapSet.new()

    by_x =
      border_points
      |> Enum.sort_by(fn {x, y} -> {x, y} end)
      |> Enum.group_by(fn {x, _} -> x end)

    by_y =
      border_points
      |> Enum.sort_by(fn {x, y} -> {y, x} end)
      |> Enum.group_by(fn {_, y} -> y end)

    by_x |> IO.inspect(label: "by_x")
    by_y |> IO.inspect(label: "by_y")

    to_check = [
      # North-facing sides
      {0, -1},
      # South
      {0, 1},
      # West
      {-1, 0},
      # East
      {1, 0}
    ]

    counts =
      to_check
      |> Enum.map(fn {ox, oy} ->
        {target_grp, main_getter, minor_getter} =
          if ox != 0 do
            {by_x, fn {x, _} -> x end, fn {_, y} -> y end}
          else
            {by_y, fn {_, y} -> y end, fn {x, _} -> x end}
          end

        target_grp
        |> Map.values()
        |> Enum.map(fn pts ->
          # Calculate sides by grouping consecutive points and counting the number of groups
          chunks =
            pts
            # Filter out points whose target side is covered
            # eg if we're looking for north-facing sides, filter out points that are below another point
            |> Enum.filter(fn {x, y} -> MapSet.member?(outside, {x + ox, y + oy}) end)
            |> Enum.chunk_while(
              {nil, []},
              fn xy, {prev, chunk} ->
                coord = minor_getter.(xy)

                if prev == nil or coord - prev == 1 do
                  {:cont, {coord, chunk ++ [coord]}}
                else
                  {:cont, chunk, {coord, [coord]}}
                end
              end,
              fn
                {prev, []} -> {:cont, {prev, []}}
                {prev, chunk} -> {:cont, chunk, {prev, []}}
              end
            )

          {{ox, oy}, pts, chunks} |> IO.inspect(label: "chekcing")

          length(chunks)
        end)
        |> Enum.sum()
      end)

    counts |> IO.inspect(label: "Side counts")

    Enum.sum(counts)
  end

  def score_regions(regions, fun) do
    regions
    |> Enum.sort_by(fn r -> r.value end)
    |> IO.inspect()
    |> Enum.map(fn r -> fun.(r) end)
    |> IO.inspect()
    |> Enum.reduce(0, fn x, acc -> acc + x end)
  end
end

defmodule Debug do
  def write_grid(grid, fun) do
    Enum.each(0..(grid.height - 1), fn y ->
      Enum.each(0..(grid.width - 1), fn x ->
        cell = Utils.Grid.at(grid, {x, y})
        IO.write(fun.(cell))
      end)

      IO.write("\n")
    end)
  end
end
