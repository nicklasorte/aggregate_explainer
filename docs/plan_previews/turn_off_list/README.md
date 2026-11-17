# Turn-off list figure previews

Design previews for [the visualization plan](../../PLAN_visualize_turn_off_list.md).
They aren't paper figures: the chosen options get rebuilt in MATLAB.

- `png/`: one preview per option (A1 to H1).
- `contact_sheet_*.png`: the options side by side, grouped by step.
- `toy_offsets_db.csv`: the exact draws from example 07, exported from MATLAB
  R2025b as `5*norminv(draw_uniform_columns_rev1(1000, 16, 1))`.
- `make_previews.py`: rebuilds every preview and asserts the published
  example 07 numbers (list size 5, 80th percentile of the check −100.07 dBm,
  89.3% of trials meeting the limit).

```bash
MPLBACKEND=Agg python3 -I make_previews.py <path to the dataviz-resources scripts folder>
```
