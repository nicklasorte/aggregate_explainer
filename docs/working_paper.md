# How an aggregate interference Monte Carlo simulation works

**DRAFT//PRE-DECISIONAL** · Working paper · Revision 0 (2026-11-17)

## Purpose

This paper explains, one step at a time, how an aggregate interference Monte
Carlo simulation turns random inputs into a result. The case is base stations
near 2.7 GHz and a radar receiver. The simulation it explains is
`init_sim_folder_FSS_neigh_rev25_fdr_github.m`
([FSS_Neighborhood](https://github.com/nicklasorte/FSS_Neighborhood)) and the
functions it calls in
[General_Movelist](https://github.com/nicklasorte/General_Movelist).

Every figure and number in this paper comes from the MATLAB code in this
repository. To rebuild them, run `run_all_examples_rev1`.

## 1. The one idea: a uniform draw becomes a model value

The simulation doesn't draw clutter loss, EIRP, or path loss directly. For each
base station and each Monte Carlo iteration, it draws three independent numbers
between 0 and 1, one for each input. Each number is then read as a percentage
and looked up on that input's curve:

1. Draw *u*, uniform on (0, 1).
1. Convert it to a percentage: *p* = 100 *u*.
1. Read the model value at *p*.

Each curve answers the question "what value is not exceeded *p* percent of the
time (or at *p* percent of locations)?" That curve is the inverse of the
cumulative distribution function (CDF). Feeding a uniform draw through an
inverse CDF produces draws that follow the model's distribution. This method
is called inverse-transform sampling.

Each example that follows has the same three panels: the uniform input, the
curve that maps a percentage to a value, and the distribution that comes out.

The received power from one base station in one iteration is then:

> received power (dBm) = EIRP draw − path loss draw − clutter loss draw
> + antenna gains

Section 5 (planned) covers how those per-station powers are added and how the
turn-off list is built.

## 2. Example 1: clutter loss (ITU-R P.2108-1), 2 km, 2.7 GHz

**Code:** `examples/example_01_p2108_2km_2700mhz_rev1.m`,
`src/p2108_terrestrial_clutter_loss_vector_rev2.m`

### The model

Recommendation ITU-R P.2108-1 (09/2021), Annex 1, Section 3.2, gives the
clutter loss for a terminal inside urban or suburban clutter. It is the
current version of the Recommendation. For frequency *f* (GHz), path length
*d* (km), and location percentage *p*:

| Equation | Expression |
| --- | --- |
| (4a) | *L*<sub>l</sub> = −2 log<sub>10</sub>(10<sup>−5 log<sub>10</sub>(*f*) − 12.5</sup> + 10<sup>−16.5</sup>) |
| (5a) | *L*<sub>s</sub> = 32.98 + 23.9 log<sub>10</sub>(*d*) + 3 log<sub>10</sub>(*f*) |
| (3b) | σ<sub>cb</sub> = √[(σ<sub>l</sub>² 10<sup>−0.2 *L*<sub>l</sub></sup> + σ<sub>s</sub>² 10<sup>−0.2 *L*<sub>s</sub></sup>) / (10<sup>−0.2 *L*<sub>l</sub></sup> + 10<sup>−0.2 *L*<sub>s</sub></sup>)], with σ<sub>l</sub> = 4 dB (4b) and σ<sub>s</sub> = 6 dB (5b) |
| (3a) | *L*<sub>ctt</sub> = −5 log<sub>10</sub>(10<sup>−0.2 *L*<sub>l</sub></sup> + 10<sup>−0.2 *L*<sub>s</sub></sup>) − σ<sub>cb</sub> *Q*<sup>−1</sup>(*p*/100) |
| (6) | *L*<sub>ctt</sub> may not exceed the value computed for *d* = 2 km |

*Q*<sup>−1</sup> is the inverse complementary normal distribution function.
The model covers 0.5 to 67 GHz and paths of at least 0.25 km (1 km when the
correction is applied at both ends).

Equation (3a) is a median term minus σ<sub>cb</sub> times a standard normal
quantile. In other words, **P.2108 clutter loss is a normal distribution in
dB**, and (3a) is its inverse CDF.

### Worked example

At *f* = 2.7 GHz and *d* = 2 km:

| Term | Value |
| --- | --- |
| *L*<sub>l</sub> (4a) | 29.30 dB |
| *L*<sub>s</sub> (5a) | 41.47 dB |
| σ<sub>cb</sub> (3b) | 4.01 dB |
| Median *L*<sub>ctt</sub> (3a, *p* = 50) | 29.29 dB |

*L*<sub>s</sub> is 12 dB above *L*<sub>l</sub>, so the *L*<sub>l</sub> term
controls the result: at 2 km the loss is at its ceiling, a normal distribution
with a 29.3 dB median and a 4.0 dB standard deviation.

### Uniform in, clutter loss out

![P.2108 clutter loss at 2 km and 2.7 GHz](figures/fig01_p2108_2km_2700mhz.png)

*Figure 1. Left: 100,000 uniform draws. Center: the P.2108 curve that maps a
location percentage to a loss, with the table percentiles marked. Right: the
clutter loss draws.*

| *p* (%) | Model (dB) | 100,000 draws (dB) | Simulation grid (dB) |
| --- | --- | --- | --- |
| 1 | 19.97 | 19.91 | 19.90 |
| 5 | 22.70 | 22.65 | 22.64 |
| 10 | 24.16 | 24.14 | 24.14 |
| 50 | 29.29 | 29.30 | 29.30 |
| 90 | 34.43 | 34.48 | 34.49 |
| 95 | 35.89 | 35.96 | 35.97 |
| 99 | 38.62 | 38.65 | 38.65 |

The draws reproduce the model to within 0.1 dB. The last column makes the
draws the way the production simulation does: it tabulates the model at 47
percentages from 0.001 to 99.999 and interpolates linearly between them. The
two methods agree to within 0.02 dB at these percentiles.

### What the check against P.2108-1 found

The function came from `general_terrestrial_pathloss`. Checked against the
Recommendation and the NTIA/ITS reference implementation
([NTIA/p2108](https://github.com/NTIA/p2108)), the equations and constants
match. Two things changed in `_rev2`:

- **Equation (6).** The original clamps the distance to 2 km before the
  calculation. The Recommendation and the NTIA code compute the loss at *d*
  and at 2 km and take the smaller. The two differ at high percentages on
  paths shorter than 2 km, because σ<sub>cb</sub> changes with distance. At
  3.5 GHz, 1 km, *p* = 99.9, the original returns 43.4 dB; the NTIA test
  vector is 42.8 dB. The largest difference found is 2.0 dB (1.6 GHz, 0.5 km,
  *p* = 99.9). At *p* ≤ 50, and at 2 km and beyond, there is no difference, so
  the worked example here is unaffected.
- **Output shape.** The documented shape, distances by percentages, now holds
  for row and matrix distance inputs.

`_rev2` passes all seven NTIA test vectors. One behavior is a project
convention, not part of P.2108-1: below 0.25 km the function returns 0 dB,
where the Recommendation gives no value.

## 3. Example 2: base station EIRP

**Code:** `examples/example_02_bs_eirp_distribution_rev1.m`,
`src/read_bs_eirp_distribution_rev1.m`,
`src/sample_from_percentile_table_rev1.m`

### The input

Base station EIRP toward the horizon varies with traffic load and beam
steering. The simulation describes it with a table of percentiles for the
0° azimuth, 0° elevation direction (`data/7Ghz 0azi 0ele EIRP.xlsx`, from
FSS_Neighborhood). The workbook doesn't state units.

| Percentile | 0 | 10 | 20 | 30 | 40 | 50 | 60 | 70 | 80 | 90 | 100 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| EIRP (dB) | 19.5 | 25.25 | 28 | 29.25 | 30.25 | 31.75 | 32.75 | 33.75 | 35.5 | 38.5 | 42.5 |
| Offset from median (dB) | −12.25 | −6.5 | −3.75 | −2.5 | −1.5 | 0 | 1 | 2 | 3.75 | 6.75 | 10.75 |

The simulation uses the last row. It sets a fixed median EIRP for each base
station and adds the offset drawn from this table. Only the shape of the
distribution matters, not its absolute level.

### Uniform in, EIRP out

Here the inverse CDF is the table itself. The code interpolates between the 11
points at 100 *u*.

![Base station EIRP distribution](figures/fig02_bs_eirp_distribution.png)

*Figure 2. Left: 100,000 uniform draws. Center: the percentile table (points)
and the spline through it. Right: the EIRP draws.*

Things to notice:

- The distribution spans 23 dB, from 12.25 dB below the median to 10.75 dB
  above it. It is wider and less symmetric than the clutter loss distribution.
- The two peaks in the right panel are where the table is flattest (30th to
  40th and 60th to 70th percentiles): many percentages map to nearly the same
  EIRP. With only 11 points, the fine shape of the output depends on the
  interpolation. Treat the peaks as a feature of the table, not as two
  operating modes.
- The simulation interpolates with a spline. On this table the spline never
  decreases, and it differs from shape-preserving interpolation (`pchip`) by
  at most 0.06 dB and from straight lines by at most 0.47 dB.

## 4. Example 3: path loss (ITM point-to-point), flat terrain, 100 km, 2.7 GHz

**Code:** `examples/example_03_itm_flat_100km_2700mhz_rev1.m`, with
`itm_p2p_rev1` from [matlab_itm](https://github.com/nicklasorte/matlab_itm)

### The model

The Irregular Terrain Model (ITM, Longley-Rice) version 1.4 predicts basic
transmission loss over a terrain profile. In point-to-point mode it takes a
*reliability*: the percentage of time for which the loss is not exceeded.
Sweeping the reliability from 0 to 100 traces the inverse CDF of the loss over
time, which reflects changes in the atmosphere.

The example removes terrain from the problem: the profile is flat (0 m
elevation everywhere), 100 km long, sampled every 100 m.

| Setting | Value |
| --- | --- |
| Frequency | 2700 MHz |
| Path | 100 km, flat, 1,001 points |
| Antenna heights | TX 30 m, RX 10 m above ground |
| Confidence | 50 % |
| Climate | 5, continental temperate |
| Surface refractivity *N*<sub>0</sub> | 301 N-units |
| Polarization | Vertical |
| Ground | ε = 25, σ = 0.02 S/m |
| Mode of variability | 13 (broadcast, no location variability) |

On this path the two radio horizons are 22.6 km and 13.0 km from the
terminals, well short of meeting, so ITM reports the troposcatter mode.
Free-space loss is 141.08 dB. ITM's reference attenuation adds 58.97 dB.

### Uniform in, path loss out

![ITM loss on a flat 100 km path at 2.7 GHz](figures/fig03_itm_flat_100km_2700mhz.png)

*Figure 3. Left: 100,000 uniform draws. Center: ITM loss against reliability.
Right: the path loss draws.*

| Reliability (%) | Model (dB) | 100,000 draws (dB) | Simulation grid (dB) |
| --- | --- | --- | --- |
| 1 | 174.38 | 174.47 | 174.45 |
| 5 | 181.79 | 181.67 | 181.66 |
| 10 | 185.74 | 185.65 | 185.64 |
| 50 | 197.13 | 197.07 | 197.07 |
| 90 | 206.16 | 206.13 | 206.13 |
| 95 | 208.72 | 208.68 | 208.68 |
| 99 | 213.53 | 213.40 | 213.43 |

Things to notice:

- The spread is large. Between the 1st and 99th percentiles the loss changes
  by 39 dB, far more than clutter loss (19 dB) or EIRP (23 dB over its full
  range). On a long over-the-horizon path, the time variability of path loss
  is the largest random term.
- The distribution is skewed. The median is 197.1 dB, but the low-loss tail
  (the interference-relevant side) reaches 22.8 dB below it at 1 %, while the
  high-loss tail reaches only 16.4 dB above it at 99 %.
- The draws match the model to within about 0.1 dB, the sampling error for
  100,000 draws.

### Confidence is a second axis

ITM also takes a *confidence*, which covers how much one path differs from
another that looks the same on paper. The simulation holds it at 50 %.

| Reliability (%) | Confidence 10 % | Confidence 50 % | Confidence 90 % |
| --- | --- | --- | --- |
| 1 | 162.53 | 174.38 | 186.23 |
| 10 | 177.20 | 185.74 | 194.28 |
| 50 | 190.03 | 197.13 | 204.23 |
| 90 | 198.12 | 206.16 | 214.20 |
| 99 | 203.67 | 213.53 | 223.38 |

Values are basic transmission loss in dB. Moving confidence from 50 % to 10 %
lowers the median loss by 7.1 dB.

## 5. The three inputs side by side

| Input | Model | What the percentage means | Median | 1 % to 99 % span |
| --- | --- | --- | --- | --- |
| Clutter loss, 2 km | ITU-R P.2108-1 | Locations | 29.29 dB | 18.7 dB |
| EIRP offset | Percentile table | Operating states | 0 dB | 23 dB (0 % to 100 %) |
| Path loss, flat 100 km | ITM v1.4 | Time | 197.13 dB | 39.2 dB |

All three use the same mechanism: one uniform draw, one curve. They differ in
what the percentage stands for and in how wide the curve is.

## 6. Planned sections

- **From single links to an aggregate, and the turn-off list.** How the median
  (50 %) values set the order of the turn-off list, how each Monte Carlo
  iteration produces its own list size, and how a percentile of those sizes
  (for example, the 80th of 1,000) sets the final list. See
  [PLAN_turn_off_list_section.md](PLAN_turn_off_list_section.md).
- **The radar receiver.** Protection threshold, antenna pattern, and azimuth
  scan for the 2.7 GHz case.

## References

1. Recommendation ITU-R P.2108-1, *Prediction of clutter loss*, 09/2021.
1. NTIA/ITS, *Recommendation ITU-R P.2108-1, U.S. Reference Implementation*,
   <https://github.com/NTIA/p2108>, with test data at
   <https://github.com/NTIA/p2108-test-data>.
1. NTIA/ITS, *Irregular Terrain Model (ITM)*, version 1.4,
   <https://github.com/NTIA/itm>.
1. `matlab_itm`, <https://github.com/nicklasorte/matlab_itm>.
1. `FSS_Neighborhood`, <https://github.com/nicklasorte/FSS_Neighborhood>.
1. `General_Movelist`, <https://github.com/nicklasorte/General_Movelist>.
