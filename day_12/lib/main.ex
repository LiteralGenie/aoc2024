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
    @enforce_keys [:inside, :border, :value, :area, :perimeter]
    defstruct [:inside, :border, :value, :area, :perimeter]
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

            border = calc_all_segments(outside, inside)

            border =
              Enum.sort_by(border, fn seg ->
                %Segment{x: {x1, x2}, y: {y1, y2}} = seg
                {x1, y1, x2, y2}
              end)

            area = MapSet.size(inside)

            perimeter =
              Enum.reduce(border, 0, fn seg, perim ->
                perim + Solver.Segment.length(seg)
              end)

            regions =
              regions ++
                [
                  %Region{
                    inside: inside,
                    border: border,
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

    Debug.write_borders(grid, regions)

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

  defp calc_all_segments(outside, inside) do
    {_, segments} =
      outside
      |> Enum.reduce({outside, []}, fn xy, {unseen, segments} ->
        if not MapSet.member?(unseen, xy) do
          # No-op if point is already part of some segment
          {unseen, segments}
        else
          # Calc segment containing this point
          {segment, seen} = calc_segment(xy, outside, inside)
          segments = segments ++ [segment]

          unseen = MapSet.difference(unseen, seen)
          {unseen, segments}
        end
      end)

    segments
  end

  # Trace out the border segment from a given start point
  defp calc_segment(start, outside, inside) do
    {sx, sy} = start

    {above, touches_upper} = calc_segment_in_dir(start, outside, inside, {0, -1})
    {below, touches_lower} = calc_segment_in_dir(start, outside, inside, {0, 1})
    vert = MapSet.union(above, below)

    {left, touches_left} = calc_segment_in_dir(start, outside, inside, {-1, 0})
    {right, touches_right} = calc_segment_in_dir(start, outside, inside, {1, 0})
    horiz = MapSet.union(left, right)

    num_corners =
      -1 + Utils.i2b(touches_upper) + Utils.i2b(touches_lower) + Utils.i2b(touches_left) +
        Utils.i2b(touches_right)

    {segment, seen} =
      if MapSet.size(vert) > 1 do
        {_, ymin} = Enum.min_by(vert, fn {_, y} -> y end)
        {_, ymax} = Enum.max_by(vert, fn {_, y} -> y end)
        xmin = xmax = sx

        {%Segment{
           x: {xmin, xmax},
           y: {ymin, ymax},
           is_horiz: false,
           num_corners: num_corners
         }, vert}
      else
        {xmin, _} = Enum.min_by(horiz, fn {x, _} -> x end)
        {xmax, _} = Enum.max_by(horiz, fn {x, _} -> x end)
        ymin = ymax = sy

        {%Segment{
           x: {xmin, xmax},
           y: {ymin, ymax},
           is_horiz: true,
           num_corners: num_corners
         }, horiz}
      end

    IO.inspect({segment, touches_upper, touches_lower, touches_left, touches_right})

    {segment, seen}
  end

  defp calc_segment_in_dir(start, candidates, inside, dir) do
    {sx, sy} = start
    {dx, dy} = dir

    # handles weirdness from concave shapes
    touches = fn {x, y} ->
      a = MapSet.member?(inside, {x + dy, y + dx})
      b = MapSet.member?(inside, {x - dy, y - dx})
      {a, b}
    end

    has_same_touches = fn {a, b}, xy ->
      {c, d} = touches.(xy)
      (a and c) or (b and d)
    end

    start_touches = touches.(start)

    points =
      MapSet.new(
        0..MapSet.size(candidates)
        |> Enum.map(fn idx ->
          x = sx + idx * dx
          y = sy + idx * dy
          {x, y}
        end)
        |> Enum.take_while(fn xy ->
          xy == start or
            (MapSet.member?(candidates, xy) and has_same_touches.(start_touches, xy))
        end)
      )

    n = MapSet.size(points)
    next = {sx + n * dx, sy + n * dy}
    maybe_corner = MapSet.member?(inside, next)

    {points, maybe_corner}
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

  def write_borders(grid, regions) do
    find_region_value = fn xy ->
      region =
        Enum.find(regions, fn r ->
          MapSet.member?(r.inside, xy)
        end)

      if region do
        region.value
      else
        ""
      end
    end

    cmp = fn ra, rb ->
      if ra == rb do
        " "
      else
        "*"
      end
    end

    Enum.each(0..(grid.height - 1), fn y ->
      {l_prev, l_curr} =
        Enum.reduce(0..(grid.width - 1), {"", ""}, fn x, {l_prev, l_curr} ->
          center = find_region_value.({x, y})
          above = find_region_value.({x, y - 1})
          below = find_region_value.({x, y + 1})
          left = find_region_value.({x - 1, y})
          right = find_region_value.({x + 1, y})

          l_prev = l_prev <> cmp.(center, above) <> " "
          l_curr = l_curr <> center <> cmp.(center, right)

          {l_prev, l_curr}
        end)

      IO.write(l_prev <> "\n" <> l_curr <> "\n")
    end)
  end
end
