### Goal

Segment grid into regions and calculate area, perimeter, and number of sides for each region

### Segmenting regions

Segment by...

-   Iterating over unseen points
-   Finding connected points via floodfill-like algo
    -   ie for a given point, check if neighbors are connected. Repeat process (recurse) for any connected neighbors.
-   Mark connected points as seen

Boundary points are points inside the region but touching (in cardinal directions) a point outside the region.
These can be calculated easily during the segmentation process.

### Region stats

Area of each region is simply the number of interior points.

Perimeter of each region can be calculated from boundary points. By totaling how many outside points are touched by each boundary point.

The number of sides is trickier. Each point can contribute up to 4 sides but consecutive points share a side and therefore reduce the total.

However, each side is totally contained within either a row or column. So we can break the search down into a per-row and per-column basis. The number of sides within a given row is essentially the number of contiguous groups of ~points.

For example...

```
# 1 north-facing side, all points connected in first row connected
> oooooo
  o    o
  oooooo

# 2 north-facing sides, two groups of points in first row
> ooo oo
  o    o
  oooooo

# 2 north-facing sides, two groups of points in second row
# the points with their north sides covered are treated as dividers
    oo
> oooooo
  o    o
  oooooo
```

For counting south-facing sides, we do the same but treat points with their south-side covered as dividers. For counting east / west sides, we check columns instead of rows.
