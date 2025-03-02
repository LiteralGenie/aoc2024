defmodule Utils do
  defmodule Tile do
    @enforce_keys [:r, :c, :type]
    defstruct [:r, :c, :type]
  end

  defmodule Solution do
    @enforce_keys [:grid, :row_count, :col_count, :links, :jumps]
    defstruct [:grid, :row_count, :col_count, :links, :jumps]
  end

  def solve(fp, max_cheat_duration) do
    {grid, row_count, col_count} = Utils.read_input(fp)

    {_, start} = Enum.find(grid, fn {_, tile} -> tile.type === :start end)

    links = init_links(grid, row_count, col_count, %{}, start, start, 0)

    jumps =
      Enum.reduce(links, [], fn {tile_id, {tile_dist, _}}, acc ->
        tile = Map.get(grid, tile_id)

        acc ++
          (neighbors(grid, tile_id, row_count, col_count, max_cheat_duration)
           |> Enum.map(fn candidate ->
             candidate_id = hash(candidate)

             {er, ec} = candidate_id
             {sr, sc} = tile_id
             duration = abs(er - sr) + abs(ec - sc)

             candidate_link = Map.get(links, candidate_id)

             case candidate_link do
               nil ->
                 {tile_id, candidate_id, tile_dist, nil, duration}

               {candidate_dist, _} ->
                 {tile_id, candidate_id, tile_dist, candidate_dist, duration}
             end
           end)
           |> Enum.filter(fn {_, _, _, x, _} -> x != nil end)
           |> Enum.filter(fn {_, _, start_dist, end_dist, duration} ->
             end_dist > start_dist + duration
           end))
      end)

    %Solution{
      grid: grid,
      row_count: row_count,
      col_count: col_count,
      links: links,
      jumps: jumps
    }
  end

  def read_input(fp) do
    text = File.read!(fp)

    lines =
      String.split(text, "\n")

    tiles =
      lines
      |> Enum.filter(fn ln -> length(String.graphemes(ln)) > 0 end)
      |> Enum.with_index()
      |> Enum.map(fn {ln, r} ->
        ln
        |> String.graphemes()
        |> Enum.with_index()
        |> Enum.map(fn {gr, c} ->
          %Tile{
            r: r,
            c: c,
            type:
              case gr do
                "." -> :path
                "#" -> :wall
                "S" -> :start
                "E" -> :end
                _ -> raise "Invalid input character: " <> gr
              end
          }
        end)
      end)

    row_count = length(tiles)
    col_count = length(hd(tiles))

    grid =
      Map.new(Enum.flat_map(tiles, fn row -> row end), fn
        tile -> {hash(tile), tile}
      end)

    {grid, row_count, col_count}
  end

  defp hash(tile) do
    {tile.r, tile.c}
  end

  defp neighbor_coords(total_set, target_set, row_count, col_count, radius) do
    case radius do
      0 ->
        total_set

      _ ->
        expanded =
          [{-1, 0}, {1, 0}, {0, -1}, {0, 1}]
          |> Enum.flat_map(fn {r_off, c_off} ->
            Enum.map(
              target_set,
              fn {r, c} ->
                {r + r_off, c + c_off}
              end
            )
          end)
          |> MapSet.new()

        new_coords = MapSet.difference(expanded, total_set)

        new_total = MapSet.union(total_set, new_coords)

        new_total =
          MapSet.union(
            new_total,
            neighbor_coords(new_total, new_coords, row_count, col_count, radius - 1)
          )

        new_total
    end
  end

  defp neighbors(grid, tile_id, row_count, col_count, radius) do
    coords =
      neighbor_coords(
        MapSet.new([tile_id]),
        MapSet.new([tile_id]),
        row_count,
        col_count,
        radius
      )

    coords
    |> Enum.filter(fn {r, _} -> r >= 0 and r < row_count end)
    |> Enum.filter(fn {_, c} -> c >= 0 and c < col_count end)
    |> Enum.map(fn coord -> Map.get(grid, coord) end)
  end

  defp init_links(grid, row_count, col_count, links, tile, prev_tile, curr_cost) do
    next_tile =
      neighbors(grid, hash(tile), row_count, col_count, 1)
      |> Enum.find(fn candidate ->
        candidate.type != :wall and
          hash(candidate) != hash(prev_tile) and
          hash(candidate) != hash(tile)
      end)

    links =
      Map.put(
        links,
        hash(tile),
        {curr_cost, hash(next_tile)}
      )

    case next_tile.type do
      :end ->
        links = Map.put(links, hash(next_tile), {curr_cost + 1, nil})

      _ ->
        links = init_links(grid, row_count, col_count, links, next_tile, tile, curr_cost + 1)
    end
  end
end
