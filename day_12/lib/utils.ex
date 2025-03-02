defmodule Utils do
  defmodule Grid do
    @enforce_keys [:height, :width, :cells]
    defstruct [:height, :width, :cells]

    def at(grid, xy) do
      Map.get(grid.cells, xy)
    end
  end

  defmodule GridCell do
    @enforce_keys [:y, :x, :value]
    defstruct [:y, :x, :value]

    def id(cell) do
      {cell.x, cell.y}
    end
  end

  def read_input(fp) do
    cells =
      File.read!(fp)
      |> String.split("\n")
      |> Enum.take_while(fn ln -> length(String.graphemes(ln)) > 0 end)
      |> Enum.with_index()
      |> Enum.map(fn {ln, r} ->
        ln
        |> String.graphemes()
        |> Enum.with_index()
        |> Enum.map(fn {gr, c} ->
          %GridCell{
            y: r,
            x: c,
            value: gr
          }
        end)
      end)

    %Grid{
      height: length(cells),
      width: length(hd(cells)),
      cells:
        cells
        |> Enum.flat_map(fn x -> x end)
        |> Map.new(fn c -> {Utils.GridCell.id(c), c} end)
    }
  end

  def i2b(bool) do
    if bool do
      1
    else
      0
    end
  end
end
