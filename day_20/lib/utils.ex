defmodule Utils do
  defmodule Tile do
    @enforce_keys [:r, :c, :type]
    defstruct [:r, :c, :type]
  end

  defmodule Solution do
    @enforce_keys [:grid, :row_count, :col_count, :links, :jumps]
    defstruct [:grid, :row_count, :col_count, :links, :jumps]
  end

  def solve(fp) do
    {grid, row_count, col_count} = Utils.read_input(fp)

    {_, start} = Enum.find(grid, fn {_, tile} -> tile.type === :start end)

    links = init_links(grid, row_count, col_count, %{}, start, start, 0)

    jumps =
      Enum.reduce(links, [], fn {tile_id, {tile_dist, _}}, acc ->
        tile = Map.get(grid, tile_id)

        acc ++
          (neighbors(grid, tile_id, row_count, col_count, 2)
           |> Enum.map(fn candidate ->
             candidate_link = Map.get(links, hash(candidate))

             case candidate_link do
               nil ->
                 {tile_id, hash(candidate), tile_dist, nil}

               {candidate_dist, _} ->
                 {tile_id, hash(candidate), tile_dist, candidate_dist}
             end
           end)
           |> Enum.filter(fn {_, _, _, x} -> x != nil end)
           |> Enum.filter(fn {_, _, x, y} -> y > x + 2 end))
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

  defp neighbor_coords({r, c}, row_count, col_count, radius) do
    case radius do
      0 ->
        [{r, c}]

      _ ->
        [{-1, 0}, {1, 0}, {0, -1}, {0, 1}]
        |> Enum.map(fn {r_off, c_off} -> {r + r_off, c + c_off} end)
        |> Enum.flat_map(fn c -> neighbor_coords(c, row_count, col_count, radius - 1) end)
    end
  end

  defp neighbors(grid, tile_id, row_count, col_count, radius) do
    coords =
      MapSet.new(
        neighbor_coords(
          tile_id,
          row_count,
          col_count,
          radius
        )
      )

    coords
    |> Enum.filter(fn {r, _} -> r >= 0 and r < row_count end)
    |> Enum.filter(fn {_, c} -> c >= 0 and c < col_count end)
    # |> IO.inspect(label: "coords")
    |> Enum.map(fn coord -> Map.get(grid, coord) end)
  end

  defp init_links(grid, row_count, col_count, links, tile, prev_tile, curr_cost) do
    neighbors(grid, hash(tile), row_count, col_count, 1)

    next_tile =
      neighbors(grid, hash(tile), row_count, col_count, 1)
      |> Enum.find(fn tile ->
        tile.type != :wall and hash(tile) != hash(prev_tile)
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
