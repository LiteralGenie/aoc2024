defmodule Main do
  def ex1() do
    regions = Solver.solve("./lib/example1")

    IO.puts([
      "Answer: ",
      inspect(Solver.score_regions(regions))
    ])
  end

  def ex2() do
    regions = Solver.solve("./lib/example2")

    IO.puts([
      "Answer: ",
      inspect(Solver.score_regions(regions))
    ])
  end

  def ex3() do
    regions = Solver.solve("./lib/example3")

    IO.puts([
      "Answer: ",
      inspect(Solver.score_regions(regions))
    ])
  end

  def ex4() do
    regions = Solver.solve("./lib/example4")

    IO.puts([
      "Answer: ",
      inspect(Solver.score_regions(regions))
    ])
  end

  def p1() do
    regions = Solver.solve("./lib/input")

    IO.puts([
      "Answer: ",
      inspect(Solver.score_regions(regions))
    ])
  end
end

defmodule Solver do
  defmodule Region do
    @enforce_keys [:inside, :outside, :value, :area, :perimeter]
    defstruct [:inside, :outside, :value, :area, :perimeter]
  end

  defmodule Segment do
    @enforce_keys [:x, :y, :is_horiz, :num_corners]
    defstruct [:x, :y, :is_horiz, :num_corners]

    def length(segment) do
      {a, b} =
        if segment.is_horiz do
          segment.x
        else
          segment.y
        end

      length = b - a + 1 + segment.num_corners
    end

    def has(segment, xy) do
      {x, y} = xy

      {xmin, xmax} = segment.x
      {ymin, ymax} = segment.y

      xmin <= x and x <= xmax and ymin <= y and y <= ymax
    end
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

            regions =
              regions ++
                [
                  %Region{
                    inside: inside,
                    outside: outside,
                    value: Utils.Grid.at(grid, xy).value,
                    area: area,
                    perimeter: perimeter
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

  def score_regions(regions) do
    regions
    |> Enum.sort(fn a, b -> a.value < b.value end)
    |> IO.inspect()
    |> Enum.map(fn r -> r.perimeter * r.area end)
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
