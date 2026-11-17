# How an aggregate interference Monte Carlo simulation works

**DRAFT//PRE-DECISIONAL** · Working paper · Revision 1 (2026-11-17)

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

### Why the inputs are uniform random numbers

**Code:** `examples/example_00_uniform_input_rev1.m`

Every model in this paper reports its result as a percentage curve. ITU-R
P.2108-1 gives the clutter loss not exceeded at *p* percent of locations. ITM
gives the path loss not exceeded *p* percent of the time. The EIRP table gives
the EIRP not exceeded in *p* percent of operating states. To use one of these
curves in a simulation, you need a way to pick *p* so that each value turns up
as often as the model says it should. A uniform random number does that.

A uniform random number on (0, 1) has no preferred value. The chance that it
lands in any interval equals the width of that interval. It falls below 0.9 in
90% of draws, between 0.4 and 0.5 in 10% of draws, and so on. When you set
*p* = 100 *u* and read the model at *p*, the result falls below the model's
90th percentile in 90% of draws, which is exactly what the 90th percentile
means. The same holds at every percentage, so the draws reproduce the model's
whole distribution.

In symbols: if $U$ is uniform on (0, 1) and $F$ is the model's cumulative
distribution function, then $X = F^{-1}(U)$ satisfies

$$
\Pr(X \le x) = \Pr\left(F^{-1}(U) \le x\right) = \Pr\left(U \le F(x)\right) = F(x).
$$

So $X$ has exactly the model's distribution. Statisticians call this
inverse-transform sampling.

![Ten equal slices of uniform draws mapped through the clutter loss curve](figures/fig00_uniform_input.png)

*Figure 1. Left: the clutter loss curve at 2 km and 2.7 GHz, with the uniform
draws split into ten equal slices (bands). The dotted lines carry each slice
edge across to the loss axis. Right: the clutter loss draws, colored by slice.*

Figure 1 shows why the output isn't uniform even though the input is. Each
slice holds 10% of the draws, but the curve stretches the slices by different
amounts:

| Slice of $u$ | Share of draws | Clutter loss range (dB) | Width (dB) |
| --- | --- | --- | --- |
| 0% to 10% | 10.0% | below 24.2 | open-ended |
| 40% to 50% | 9.9% | 28.3 to 29.3 | 1.0 |
| 50% to 60% | 10.0% | 29.3 to 30.3 | 1.0 |
| 90% to 100% | 10.2% | above 34.4 | open-ended |

The middle slices are squeezed into 1 dB each, so the draws pile up near the
median. The end slices are stretched over the tails, so the draws thin out
there. The uniform draw decides *how often*; the model curve decides *where*.

The first five draws of Example 1 show the steps:

| Draw | $u$ | $p$ (%) | Clutter loss (dB) |
| --- | --- | --- | --- |
| 1 | 0.1128 | 11.28 | 24.44 |
| 2 | 0.0829 | 8.29 | 23.74 |
| 3 | 0.0943 | 9.43 | 24.02 |
| 4 | 0.0017 | 0.17 | 17.57 |
| 5 | 0.8048 | 80.48 | 32.74 |

Four of the five draws happen to land below 12%. A handful of uniform draws
can look lopsided; the evenness shows only over many draws, as in the left
panel of Figure 2.

#### Why not something simpler

- **Use the median of each input.** This gives one number and hides the
  spread. Section 7 shows that the received power from one base station spans
  48 dB between its 1st and 99th percentiles. A median-only answer misses all
  of it.
- **Draw the percentage from a bell curve.** This picks percentages near 50%
  more often than the model intends. The model's curve already holds the
  shape of the distribution. Shaping the input as well counts the shape twice
  and makes the tails too rare.
- **Step through a fixed grid of percentages.** A grid works for one input.
  With three inputs, every combination of grid points is needed, so a grid of
  100 percentages becomes 1,000,000 cases. Random draws cover the same space
  with far fewer trials, and the number of trials doesn't grow with the number
  of inputs.

#### Rules for using uniform draws

1. **Keep the draws strictly between 0 and 1.** A percentage of exactly 0 or
   100 has no finite value in most models; P.2108-1 would return an infinite
   value. MATLAB's `rand` never returns 0 or 1. The production simulation
   instead scales its draws to 0.001% to 99.999%, which also trims the
   extreme tails.
1. **Draw separately for each input and each base station.** If two inputs
   share one draw, they move in lockstep, and the simulation no longer models
   independent effects. Depending on the signs of the terms, it then
   overstates or understates the extremes. This paper takes each input's
   draws from its own substream of one random number stream
   (`draw_uniform_columns_rev1`), and its tests check that the correlation
   between inputs is near zero.
1. **Set the seed.** A fixed seed makes every figure and table in this paper
   reproducible, draw for draw.
1. **Use enough draws for the percentile you need.** A percentile estimated
   from $n$ draws has a standard error of about

   $$
   \mathrm{SE}(x_q) \approx \frac{1}{f(x_q)} \sqrt{\frac{q(1-q)}{n}},
   $$

   where $q$ is the percentile as a fraction and $f(x_q)$ is the probability
   density there. Tails have low density, so they need more draws. For the
   received power in Section 6 (standard deviation 10.2 dB), 100,000 draws
   give a standard error of about 0.04 dB at the median and 0.12 dB at the
   99th percentile. With 1,000 draws, the Monte Carlo size in the production
   simulation's settings (`mc_size = 1000`), the errors grow tenfold, to about
   0.4 dB and 1.2 dB.

The received power from one base station in one iteration is then:

$$
P_\mathrm{rx}\ (\mathrm{dBm}) = \mathrm{EIRP} - L_\mathrm{path} - L_\mathrm{clutter} + G_\mathrm{rx}
$$

EIRP is the equivalent isotropically radiated power of the base station,
which already includes its antenna gain. $G_\mathrm{rx}$ is the gain of the
receive antenna toward the base station. Each of the first three terms is a
separate draw.

Sections 6 and 7 do this for one base station. Sections 8 to 10 explain how
the simulation turns many base stations into a turn-off list and a zone.
Sections 11 to 13 define the terms that readers most often ask about.
Section 14 lists how this paper differs from the production simulation,
Section 15 lists planned work, and Appendix A shows figure options for the
turn-off list.

## 2. Example 1: clutter loss (ITU-R P.2108-1), 2 km, 2.7 GHz

**Code:** `examples/example_01_p2108_2km_2700mhz_rev1.m`,
`src/p2108_terrestrial_clutter_loss_vector_rev2.m`

### The model

Recommendation ITU-R P.2108-1 (09/2021), Annex 1, Section 3.2, gives the
clutter loss for a terminal inside urban or suburban clutter. It is the
version in force as of November 2026. For frequency *f* (GHz), path length
*d* (km), and location percentage *p*:

| Equation | Expression |
| ---- | -------------------------------------------------------------------------- |
| (4a) | $L_\mathrm{l} = -2\log_{10}\left(10^{-5\log_{10}(f) - 12.5} + 10^{-16.5}\right)$ |
| (5a) | $L_\mathrm{s} = 32.98 + 23.9\log_{10}(d) + 3\log_{10}(f)$ |
| (3b) | $\sigma_\mathrm{cb} = \sqrt{\dfrac{\sigma_\mathrm{l}^2\,10^{-0.2 L_\mathrm{l}} + \sigma_\mathrm{s}^2\,10^{-0.2 L_\mathrm{s}}}{10^{-0.2 L_\mathrm{l}} + 10^{-0.2 L_\mathrm{s}}}}$ |
| (4b), (5b) | $\sigma_\mathrm{l} = 4$ dB, $\sigma_\mathrm{s} = 6$ dB |
| (3a) | $L_\mathrm{ctt} = -5\log_{10}\left(10^{-0.2 L_\mathrm{l}} + 10^{-0.2 L_\mathrm{s}}\right) - \sigma_\mathrm{cb}\,Q^{-1}(p/100)$ |
| (6) | $L_\mathrm{ctt}$ can't exceed the value computed for *d* = 2 km |

$Q^{-1}$ is the inverse complementary normal distribution function.
The model covers 0.5 GHz to 67 GHz and paths of at least 0.25 km (1 km when the
correction is applied at both ends).

Equation (3a) is a median term minus $\sigma_\mathrm{cb}$ times a standard normal
quantile. In other words, P.2108 clutter loss is a normal distribution in
dB, and (3a) is its inverse CDF.

### Worked example

At *f* = 2.7 GHz and *d* = 2 km:

| Term | Value |
| --- | --- |
| $L_\mathrm{l}$ (4a) | 29.30 dB |
| $L_\mathrm{s}$ (5a) | 41.47 dB |
| $\sigma_\mathrm{cb}$ (3b) | 4.01 dB |
| Median $L_\mathrm{ctt}$ (3a, *p* = 50) | 29.29 dB |

$L_\mathrm{s}$ is 12 dB above $L_\mathrm{l}$, so the $L_\mathrm{l}$ term
controls the result: at 2 km the loss is at its ceiling, a normal distribution
with a 29.3 dB median and a 4.0 dB standard deviation.

### Uniform in, clutter loss out

![P.2108 clutter loss at 2 km and 2.7 GHz](figures/fig01_p2108_2km_2700mhz.png)

*Figure 2. Left: 100,000 uniform draws. Center: the P.2108 curve that maps a
location percentage to a loss; the dotted line traces one draw, at 90%.
Right: the clutter loss draws.*

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
  paths shorter than 2 km, because $\sigma_\mathrm{cb}$ changes with distance. At
  3.5 GHz, 1 km, *p* = 99.9, the original returns 43.4 dB; the NTIA test
  vector is 42.8 dB. The largest difference found is about 2 dB (for example,
  1.6 GHz, 0.5 km, *p* = 99.9). At *p* ≤ 50 there is no difference, and at
  2 km and beyond it is at most 0.05 dB, so the worked example here is
  unaffected.
- **Output shape.** The documented shape, distances by percentages, now holds
  for row and matrix distance inputs.

`_rev2` matches all seven NTIA test vectors, which are given to 0.1 dB. One behavior is a project
convention, not part of P.2108-1: below 0.25 km the function returns 0 dB,
where the Recommendation gives no value.

## 3. Example 2: base station EIRP

**Code:** `examples/example_02_bs_eirp_distribution_rev2.m`,
`src/read_bs_eirp_distribution_rev1.m`,
`src/fit_eirp_truncated_normal_rev1.m`

### The input

Base station EIRP toward the horizon varies with traffic load and beam
steering. The simulation describes it with a table of percentiles for the
0° azimuth, 0° elevation direction (`data/7Ghz 0azi 0ele EIRP.xlsx`, from
FSS_Neighborhood).

**Where the table comes from.** CTIA provided the table. The *7 GHz CTIA
Cellular Network Characteristics* working paper (August 10, 2026) describes
how the wireless industry built it, as an "EIRP heatmap":

1. **Measure a live network.** A base station equipment manufacturer recorded
   the scheduler data of 60 cells in a 3.7 GHz network in a suburb of Dallas,
   Texas: which beam each cell used and how much of the channel it filled, in
   every 0.5 ms transmit interval. Recording ran for five 15-minute periods
   on one day (noon to 8 PM, every two hours), about 540 million samples in
   all.
1. **Turn traffic into power by direction.** For each cell and each
   15-minute period, the beams used and their traffic load were combined with
   modeled antenna patterns (the ITU-R extended AAS model) to get the average
   power spectral density in every direction in front of the antenna. That
   gives 300 cell-period datasets (60 cells times 5 periods).
1. **Extrapolate to 7 GHz.** The same traffic was assigned to the narrower
   beams of a 7 GHz antenna (4 by 16 subarrays of 6 elements) with a peak
   traffic-beam EIRP of 71 dBm/MHz. The 7 GHz layer is assumed to reuse the
   same sites and serve the same traffic.
1. **Record percentiles by direction.** In each direction (2° steps in
   azimuth, 1° steps in elevation), the 300 values give the 0th to 100th
   percentiles in 10-point steps. The CTIA paper also describes two more
   datasets of the same kind from West Los Angeles. The workbook used here is
   the Dallas dataset.

Three consequences follow for the Monte Carlo simulation:

- **Units.** The heatmap is a power spectral density in dBm/MHz for one
  polarization. For short, this paper's text and figures write dBm; read
  every EIRP and received power in the paper as per megahertz. (TODO:
  confirm that the workbook keeps the CTIA heatmap's single-polarization,
  per-megahertz convention.)
- **What one draw means.** A draw from the table is the 15-minute average
  power of a randomly chosen cell in a randomly chosen afternoon or evening
  period. It isn't an instantaneous power. Averaging over time and beam
  directions is why the table's 100th percentile in this direction,
  42.5 dBm/MHz, is far below the 71 dBm/MHz peak of a single traffic beam.
- **Angles.** Azimuth and elevation are measured from the face of the
  antenna panel, with no mechanical downtilt. A simulation applies the site's
  downtilt and azimuth when it looks up the direction toward the receiver.
  Broadcast beams carry under 5% of the energy and aren't included.

| Percentile (%) | EIRP (dBm/MHz) | Offset from median (dB) |
| --- | --- | --- |
| 0 | 19.5 | −12.25 |
| 10 | 25.25 | −6.5 |
| 20 | 28 | −3.75 |
| 30 | 29.25 | −2.5 |
| 40 | 30.25 | −1.5 |
| 50 | 31.75 | 0 |
| 60 | 32.75 | 1 |
| 70 | 33.75 | 2 |
| 80 | 35.5 | 3.75 |
| 90 | 38.5 | 6.75 |
| 100 | 42.5 | 10.75 |

The simulation uses the last column. It sets a fixed median EIRP for each base
station and adds the offset drawn from this table. Only the shape of the
distribution matters, not its absolute level.

### How a table like this can be modeled

An active antenna system (AAS) base station steers beams toward the users it
serves, so its EIRP in any one direction changes from moment to moment. The
companion repository [imt-matlab](https://github.com/nicklasorte/imt-matlab)
shows how a per-direction EIRP table can be built from a model instead of
from measurements:

1. Model the antenna with the AAS pattern in Recommendation ITU-R M.2101-0
   (element pattern, array factor, sub-arrays, and mechanical downtilt).
1. In each Monte Carlo draw, place users at random in the sector and point
   one beam at each. The user placement itself starts from uniform draws: the
   radius is $r = \sqrt{r_\mathrm{min}^2 + u\,(r_\mathrm{max}^2 - r_\mathrm{min}^2)}$
   with $u$ uniform on (0, 1), the same inverse-transform idea as Section 1.
1. Add the simultaneous beams in linear power to get the sector EIRP in every
   azimuth and elevation direction.
1. After many draws, record the 0th to 100th percentiles of EIRP for each
   direction (`export_eirp_percentile_table` writes columns `p000` to
   `p100`).

The result has the same layout as the CTIA table: one row per direction, one
column per percentile, so it can feed the same step after a format
conversion.

The two differ in what a percentile means. In the modeled table a percentile
is over random beam pointings; it includes no traffic load or TDD activity
unless those are added. The CTIA table instead ranges over 60 measured
cells and five 15-minute periods, so it includes real traffic load and real
beam use.

**Assumption to confirm.** The table comes from the 7 GHz work. Using it here
assumes that the shape of the EIRP distribution, its spread around the median,
carries over to base stations at 2.7 GHz. (TODO: confirm, or replace with
2.7 GHz data.)

### From 11 points to a smooth distribution

The table gives only 11 points of the distribution. Drawing from it needs a
rule for the values between the points. Two rules give different shapes:

- **A spline through the points.** The production simulation does this. The
  spline is flattest near the 32nd and 59th percentiles (about 29.4 dBm and
  32.7 dBm), so it maps many percentages to nearly the same EIRP there, and
  the draws pile up in two peaks. The peaks follow the table: its steps are
  1.0 dB from the 30th to the 40th percentile, 1.5 dB from the 40th to the
  50th, and 1.0 dB from the 50th to the 60th. With 11 points rounded to
  0.25 dB, the table can't show whether that dip near the median is real.
- **A fitted normal distribution in dBm.** This paper uses this rule. It fits
  a normal distribution to the table's percentiles and cuts it off at the
  table's 0th and 100th percentiles (19.5 dBm and 42.5 dBm), so no draw falls
  outside the measured range. It smooths over the dip. A normal distribution in dB is a lognormal
  distribution in watts. The choice is empirical: it is the simplest smooth
  shape that matches the table.

The fit is least squares on the nine interior percentiles. It has a mean of
31.74 dBm and a standard deviation of 5.04 dB before the cutoff. After the
cutoff, the median is 31.68 dBm and the standard deviation is 4.67 dB.

| Percentile (%) | Table (dBm) | Fitted (dBm) | Fitted − table (dB) |
| --- | --- | --- | --- |
| 10 | 25.25 | 25.42 | 0.17 |
| 20 | 28.00 | 27.54 | −0.46 |
| 30 | 29.25 | 29.10 | −0.15 |
| 40 | 30.25 | 30.43 | 0.18 |
| 50 | 31.75 | 31.68 | −0.07 |
| 60 | 32.75 | 32.93 | 0.18 |
| 70 | 33.75 | 34.25 | 0.50 |
| 80 | 35.50 | 35.77 | 0.27 |
| 90 | 38.50 | 37.81 | −0.69 |

The fit is within 0.7 dB of every table point, with a root-mean-square error
of 0.35 dB. The largest misfit is at the 90th percentile, where the fit is
0.69 dB below the table: the measured upper tail is a little heavier than a
normal distribution's. Measured from the median, the fit's 95th percentile is
7.7 dB up, and the spline's is 8.6 dB up. The upper tail is the one that
matters for interference, so the fit is slightly optimistic there. For one
base station the effect on received power is small (Section 6), but check it
again when many base stations are added together.

### Uniform in, EIRP out

![Base station EIRP from the fitted normal distribution](figures/fig02_bs_eirp_distribution.png)

*Figure 3. Left: 100,000 uniform draws. Center: the fitted distribution's
inverse CDF (line) and the CTIA table (circles). Right: the EIRP draws, a
single bell-shaped peak.*

The figure shows the following:

- The draws have one peak, at the median, and fall off on both sides.
- 98% of draws fall within 20.4 dB: from 21.1 dBm (1st percentile) to
  41.5 dBm (99th percentile).
- Choosing the fit over the spline changes the received power in Section 6 by
  at most 0.4 dB at any listed percentile.

## 4. Example 3: path loss (ITM point-to-point), flat terrain, 100 km, 2.7 GHz

**Code:** `examples/example_03_itm_flat_100km_2700mhz_rev1.m`, with
`itm_p2p_rev1` from [matlab_itm](https://github.com/nicklasorte/matlab_itm)

### The model

The Irregular Terrain Model (ITM, Longley-Rice) version 1.4 predicts basic
transmission loss over a terrain profile. In point-to-point mode it takes a
*reliability*: the percentage of time for which the loss is not exceeded.
Sweeping the reliability from just above 0 to just below 100 traces the
inverse CDF of the loss over time, which reflects changes in the atmosphere.

ITM's time variability describes hourly median losses over a long period. It
doesn't include fading within the hour. Percentages below 1% and above 99%
are extrapolations, and ITM flags them with a caution that the examples turn
off. Treat draws in those tails as less certain than the rest.

The example removes terrain from the problem: the profile is flat (0 m
elevation everywhere), 100 km long, sampled every 100 m.

| Setting | Value |
| --- | --- |
| Frequency | 2700 MHz |
| Path | 100 km, flat, 1,001 points |
| Antenna heights | TX 30 m, RX 10 m above ground |
| Confidence | 50% |
| Climate | 5, continental temperate |
| Surface refractivity $N_0$ | 301 N-units |
| Polarization | Vertical |
| Ground | ε = 25, σ = 0.02 S/m |
| Mode of variability | 13 (broadcast, no location variability) |

ITM has no single path loss equation. It computes a *reference attenuation*
below free space from the path geometry, using one of three methods:
two-ray (line of sight), knife-edge and smooth-earth diffraction, or
troposcatter. It then adds the time, location, and situation variability
for the requested percentages:

$$
L_b(q_T, q_C) = L_\mathrm{fs} + A_\mathrm{ref} + Y(q_T, q_C),
$$

where $L_\mathrm{fs}$ is free-space loss, $A_\mathrm{ref}$ is the reference
attenuation, $q_T$ is the reliability (time), $q_C$ is the confidence, and
$Y$ is the variability term in dB, which grows with the reliability and the
confidence. The full method is in the NTIA/ITS
reference code (see References).

On this path the two radio horizons are 22.6 km and 13.0 km from the
terminals, well short of meeting, so ITM reports the troposcatter mode.
Free-space loss is 141.08 dB, and the median loss is 56 dB above it.

### Uniform in, path loss out

![ITM loss on a flat 100 km path at 2.7 GHz](figures/fig03_itm_flat_100km_2700mhz.png)

*Figure 4. Left: 100,000 uniform draws. Center: ITM loss against the time
percentage; the dotted line traces one draw, at 90%. Right: the path loss
draws.*

| Reliability (%) | Model (dB) | 100,000 draws (dB) | Simulation grid (dB) |
| --- | --- | --- | --- |
| 1 | 174.38 | 174.47 | 174.45 |
| 5 | 181.79 | 181.67 | 181.66 |
| 10 | 185.74 | 185.65 | 185.64 |
| 50 | 197.13 | 197.07 | 197.07 |
| 90 | 206.16 | 206.13 | 206.13 |
| 95 | 208.72 | 208.68 | 208.68 |
| 99 | 213.53 | 213.40 | 213.43 |

The figure shows the following:

- The spread is large. Between the 1st and 99th percentiles the loss changes
  by 39 dB, far more than clutter loss (19 dB) or EIRP (20 dB). On a long over-the-horizon path, the time variability of path loss
  is the largest random term in this example.
- The distribution is skewed. The median is 197.1 dB, but the low-loss tail
  (the interference-relevant side) reaches 22.8 dB below it at 1%, while the
  high-loss tail reaches only 16.4 dB above it at 99%.
- The draws match the model to within about 0.1 dB, the sampling error for
  100,000 draws.

### Confidence is a second axis

ITM also takes a *confidence*, which covers how much one path differs from
another that looks the same on paper. The simulation holds it at 50%.

| Reliability (%) | Confidence 10% | Confidence 50% | Confidence 90% |
| --- | --- | --- | --- |
| 1 | 162.53 | 174.38 | 186.23 |
| 10 | 177.20 | 185.74 | 194.28 |
| 50 | 190.03 | 197.13 | 204.23 |
| 90 | 198.12 | 206.16 | 214.20 |
| 99 | 203.67 | 213.53 | 223.38 |

Values are basic transmission loss in dB. Moving confidence from 50% to 10%
lowers the median loss by 7.1 dB.

### How the distribution changes with distance

**Code:** `examples/example_06_itm_vs_distance_rev1.m`

Example 3 looks at one distance. Figure 5 repeats it at every whole distance
from 1 km to 200 km. Nothing else changes: the terrain stays flat, the
antennas stay at 30 m and 10 m, and the confidence stays at 50%. At each
distance only the time percentage moves, from 0% to 100%, which traces out
that distance's distribution of path loss.

![ITM path loss distribution from 1 km to 200 km](figures/fig07_itm_vs_distance_2700mhz.png)

*Figure 5. Left: path loss against distance. The dark line is the median; the
bands cover 25% to 75%, 5% to 95%, and 1% to 99% of time; the dashed line is
free-space loss. Loss increases downward. Right: the width of the 5% to 95%
and 1% to 99% bands.*

| Distance (km) | ITM mode | Free space (dB) | Median (dB) | 1% to 99% spread (dB) |
| --- | --- | --- | --- | --- |
| 1 | Line of sight | 101.08 | 101.08 | 0.02 |
| 10 | Line of sight | 121.08 | 121.05 | 1.49 |
| 25 | Line of sight | 129.04 | 131.34 | 7.88 |
| 50 | Diffraction | 135.06 | 169.08 | 28.24 |
| 100 | Troposcatter | 141.08 | 197.13 | 39.15 |
| 150 | Troposcatter | 144.60 | 202.53 | 37.83 |
| 200 | Troposcatter | 147.10 | 208.11 | 32.74 |

The figure shows three regimes:

- **Within line of sight (up to 35 km).** The path loss stays close to free
  space, and the time percentage barely matters: the spread is under 2 dB out
  to 10 km. Here a Monte Carlo draw of path loss changes little.
- **Past the radio horizon (36 km to 68 km).** The signal must bend over the
  curve of the earth. The median loss climbs about 1.3 dB per km, and the
  spread grows quickly, to 35 dB by 68 km.
- **Troposcatter (69 km and beyond).** The signal arrives by scattering off
  the atmosphere. The median loss climbs slowly, and the spread stays wide:
  it peaks at 39.5 dB near 115 km and narrows to 32.7 dB at 200 km.

For a Monte Carlo simulation of many base stations, the regimes matter more
than any single number. Base stations inside the radio horizon contribute
nearly fixed power. Base stations beyond it contribute power that changes by
tens of decibels from draw to draw, and those draws set the tails of the
aggregate. The spread curve doesn't change slope exactly where the mode
changes, because ITM's time variability depends on an effective distance,
not on the mode label.

## 5. The three inputs side by side

| Input | Model | What the percentage means | Median | 1% to 99% span |
| --- | --- | --- | --- | --- |
| Clutter loss, 2 km | ITU-R P.2108-1 | Locations | 29.29 dB | 18.7 dB |
| EIRP | Normal fit to the CTIA table | Operating states | 31.68 dBm | 20.4 dB |
| Path loss, flat 100 km | ITM v1.4 | Time | 197.13 dB | 39.1 dB |

Path loss has the widest spread here because the base station is 100 km
away, well past the radio horizon. Within line of sight, its spread would be
the smallest of the three (Figure 5).

All three use the same mechanism: one uniform draw, one curve. They differ in
what the percentage stands for and in how wide the curve is.

## 6. Example 4: one base station at 100 km

**Code:** `examples/example_04_single_bs_100km_rev2.m`,
`src/single_bs_inputs_rev1.m`, `src/draw_uniform_columns_rev1.m`,
`src/sum_of_independent_db_rev1.m`

### The calculation

This example puts the three inputs together for one base station that is
100 km from the receiver:

$$
P_\mathrm{rx} = \mathrm{EIRP} - L_\mathrm{path} - L_\mathrm{clutter}
$$

Each Monte Carlo trial does the following:

1. Draws three independent uniform numbers, one for each input.
1. Reads the fitted EIRP distribution (Example 2) at the first, the ITM curve
   (Example 3) at the second, and the P.2108 curve at the third. At 100 km,
   Equation (6) holds the clutter loss at its 2 km distribution (Example 1).
1. Adds the EIRP and subtracts the two losses, all in dB.

The example rests on these assumptions:

- **Independent inputs.** The three draws in a trial don't depend on each
  other. If they did (for example, if traffic load and the atmosphere both
  followed the time of day), the tails would be wider.
- **Clutter at the base station end only.** The receiver end has no clutter
  loss. P.2108-1 Section 3.2 is for a terminal inside the clutter; whether
  that fits a 30 m base station antenna is an open question (TODO).
- **Base station pointed at the receiver.** The EIRP table is for 0° azimuth
  and 0° elevation. The production simulation also applies a horizontal
  antenna pattern for base stations that point elsewhere.
- **Illustrative EIRP level.** The example uses the table's values in dBm as
  they are. The table states no reference bandwidth, so don't compare the
  received power here with a protection threshold. The table comes from
  7 GHz work (Section 3).
- **Illustrative geometry.** Flat terrain, antenna heights of 30 m and 10 m,
  and a 0 dBi receive antenna. The radar antenna and its height come in a
  later section (TODO).

### Three distributions in, one distribution out

![Received power from one base station at 100 km](figures/fig04_single_bs_100km_2700mhz.png)

*Figure 6. Top: the three input distributions from 100,000 trials. Bottom
left: the received power, with its median, 95th, and 99th percentiles. Bottom
right: its CDF from the trials and from an exact calculation.*

| Percentile | Monte Carlo (dBm) | Exact convolution (dBm) | With the production spline for EIRP (dBm) |
| --- | --- | --- | --- |
| 1 | −216.47 | −216.54 | −216.80 |
| 5 | −210.21 | −210.20 | −210.35 |
| 10 | −206.81 | −206.78 | −206.92 |
| 50 | −194.32 | −194.32 | −194.36 |
| 80 | −185.57 | −185.53 | −185.50 |
| 90 | −180.66 | −180.68 | −180.53 |
| 95 | −176.59 | −176.51 | −176.43 |
| 99 | −168.27 | −168.31 | −168.15 |

Two checks back up the Monte Carlo column:

- **Exact convolution.** Because the three inputs are drawn independently, the
  distribution of their sum is the convolution of their distributions. That
  calculation uses no random numbers. It agrees with the trials to within
  0.1 dB.
- **EIRP rule.** Running the same trials with the production simulation's
  spline for EIRP moves no listed percentile by more than 0.4 dB.

The median of the sum, −194.32 dBm, is close to the sum of the three medians,
−194.74 dBm. The tails are a different story, as the next section shows.

## 7. Where the spread comes from

**Code:** `examples/example_05_spread_rev1.m`

The received power in Section 6 spans 48 dB from the 1st to the 99th
percentile. This section asks which input causes that spread. It reruns the
same 100,000 trials three more times, each time holding one input at its
median while the other two still vary.

![Where the spread of received power comes from](figures/fig05_single_bs_100km_spread.png)

*Figure 7. Left: the range of received power with all three inputs varying
(top) and with each input held at its median. Thick bars cover 5% to 95% of
trials, thin lines 1% to 99%, circles mark the median. The diamond marks the
1%-each stack. Right: each input's share of the variance of the received
power.*

| Scenario | 5% to 95% range (dB) | 1% to 99% range (dB) | Standard deviation (dB) |
| --- | --- | --- | --- |
| All three vary | 33.6 | 48.2 | 10.24 |
| EIRP held at median | 30.0 | 43.2 | 9.14 |
| Path loss held at median | 20.3 | 27.9 | 6.14 |
| Clutter loss held at median | 31.0 | 44.4 | 9.42 |

The figure and table support four findings:

- **Path loss sets most of the spread.** It supplies 64% of the variance of
  the received power; EIRP supplies 21% and clutter loss 15%. Holding path
  loss at its median narrows the middle 90% of trials from 33.6 dB to
  20.3 dB. Holding EIRP fixed narrows it by 3.7 dB, and holding clutter loss fixed
  by 2.6 dB.
- **Standard deviations combine as a root sum of squares.** The standard
  deviations of the inputs are 8.20 dB, 4.66 dB, and 4.02 dB. Simple addition
  gives 16.9 dB, but the output standard deviation is 10.24 dB, close to the
  square root of the sum of their squares (10.26 dB). This rule holds because
  the inputs are drawn independently.
- **The 1% tails don't coincide.** Take the 1% tail of each input together
  (99th percentile EIRP, 1st percentile path loss, 1st percentile clutter
  loss): the "1%-each stack" gives −152.8 dBm. The 99th percentile of the
  actual sum is −168.3 dBm, 15.4 dB lower. With independent inputs, all three
  land in their 1% tails together in about one trial in a million, so the
  stack describes a far rarer event than the 99th percentile does.
- **Read the output percentile with care.** The 99th percentile of received
  power is over trials. Each trial combines a time (path loss), a location
  (clutter loss), and an operating state (EIRP), so "1% of trials" doesn't
  mean "1% of the time." For one real base station, the location doesn't
  change from hour to hour.
- **On this path, path loss matters most.** The ranking holds for one flat
  100 km path. Figure 5 shows that within line of sight the time variability
  of path loss nearly vanishes, and EIRP and clutter loss then set the
  spread. The variance share also measures random spread, not model error: a
  wrong EIRP level or a wrong confidence setting shifts every trial and
  doesn't show up here.
- **A wide spread in decibels raises the average power.** Powers from many
  base stations add in watts, not in decibels. For a bell curve in decibels
  with a 10.2 dB standard deviation, the mean power is about 12 dB above the
  median. The planned aggregate sections build on this point.

## 8. From many base stations to one turn-off list

**Code:** `examples/example_07_turn_off_list_toy_rev1.m`

Sections 1 to 7 follow the power from one base station. A federal site sees
many. This section explains how the simulation decides which base stations
near the site must stop transmitting, and how many. Its output is the
*turn-off list*.

### The method in four steps

For one candidate radius around one protection point, the simulation does the
following:

1. **Rank the base stations once, by median power.** For every base station
   inside the radius, compute the power it delivers to the federal receiver
   with each random input at its median (the 50th percentile): median EIRP,
   median path loss, and median clutter loss, plus the antenna gains toward
   the receiver. Sort the base stations from strongest to weakest. This order
   is fixed before any Monte Carlo trial runs. No trial changes it.
1. **In each trial, find the cut point.** Redraw every base station's power
   (Section 1). Walk down the fixed order, turning base stations off one at
   a time, until the aggregate from the rest meets the limit. The number
   turned off is that trial's list size. The order stays the same in every
   trial; only the cut point moves.
1. **Take a percentile of the list sizes.** After all the trials (1,000 in
   the production settings), sort the list sizes and take the chosen
   percentile, for example the 80th. Round up. The production code then adds
   one more base station as a margin.
1. **Read off the list.** The turn-off list is the top of the fixed order,
   down to that count.

When two criteria apply (for example, a long-term and a short-term
criterion, Section 11), the production code sizes the list for each and uses
the larger.

### Why the median, and why a fixed order

The ranking uses the median because it is the single most typical value of
each random input. It is the 50th percentile, not the mean: in watts, the
mean of a quantity that varies by many decibels is higher than its median
(Section 7). The median gives one ranking that doesn't depend on the luck of
any one trial.

The order is fixed because a turn-off list has to be one list. If each trial
picked its own base stations, 1,000 trials would produce 1,000 different
lists, and there would be no way to combine them into one operating rule.
With a fixed order, the only thing that varies from trial to trial is one
number, the cut point, and one number has a percentile.

This way of building the list is *greedy*: it turns off the largest
contributor first, then the next largest, and stops as soon as the limit is
met. It doesn't look ahead or try other combinations.

### A worked example

The example uses illustrative numbers small enough to follow by hand. Six
base stations sit inside the radius, with median received powers of −98,
−100, −102, −104, −106, and −108 dBm, already in median order. Four more
sit outside it, at −110 to −116 dBm. Each base station's power varies
around its median by a bell curve with a 5 dB standard deviation, a stand-in
for the combined EIRP, path loss, and clutter loss draws of Sections 2 to 6.
The limit on the aggregate is −99 dBm.

With every base station at its median, the six inside give −94.0 dBm.
Turning off the first two leaves −98.4 dBm, still over the limit;
turning off the first three leaves −100.9 dBm, under it. At the medians,
the list size is 3.

The first three trials redraw every power:

| Trial | Powers in median order (dBm) | Turned off |
| --- | --- | --- |
| 1 | −98.1, −93.3, −107.4, −109.2, −110.8, −109.9 | 2 |
| 2 | −101.8, −101.4, −97.4, −98.2, −110.4, −105.5 | 4 |
| 3 | −102.1, −104.7, −99.5, −114.5, −103.2, −99.8 | 5 |

In trial 1, the second base station drew a high power, and turning off the
first two is enough. In trial 3, the fixed order turns off the first two even
though they drew low powers, and the cut point lands at 5.

For 27 other ways to draw this example, step by step, see Appendix A.

![Turn-off list worked example](figures/fig08_turn_off_list_toy.png)

*Figure 8. Left: the share of 1,000 trials that needed each number of base
stations off with the fixed median order (bars), and if each trial could
choose its own base stations (line). Right: the aggregate in the validation
run, with the list applied, against the limit.*

Over 1,000 trials, the list size ranges from 0 to 6. Its 80th percentile is
4, so the turn-off list is 5 base stations (4 plus the margin of one).

The line in Figure 8 answers a question that reviewers ask: what does the
fixed order cost? A trial that could choose its own base stations would need
2.64 off on average, against 3.34 with the fixed order, and 3 at the 80th
percentile, against 4. In this example, a single list that works for every
trial costs about one more base station than an ideal list for each trial.

The production code can also rank the base stations with a near-optimal
order (`tf_opt=1`) instead of the simple sort. It accounts for the radar
antenna pattern: a base station that is strong at one radar azimuth may
matter less than several weaker ones at the azimuth that sets the aggregate.
The mechanics are the same: one fixed order, one cut point per trial, and a
percentile of the cut points.

## 9. Two simulations: build the list, then check it

For each candidate radius, the production code runs two Monte Carlo
simulations with different questions:

| | Simulation 1: build the list | Simulation 2: check the list |
| --- | --- | --- |
| Question | How many base stations inside this radius must be off? | With that list off, does the aggregate meet the limit often enough? |
| Base stations included | Only those inside the candidate radius | Every base station in the study area that isn't on the list, inside the radius and outside it |
| Output | The turn-off list (Section 8) | The aggregate at the chosen percentile, compared with the limit: pass or fail |

The two simulations are needed because the list is built without the base
stations outside the radius. Those base stations can't be turned off at this
radius, but they still add interference. Simulation 2 adds them back and asks
whether the radius works with the list it was given. A radius can fail even
if every base station inside it is turned off, when the base stations outside
it are enough to exceed the limit on their own.

In the worked example, simulation 2 turns off the five listed base stations,
keeps the sixth inside and the four outside on, and redraws all ten powers
1,000 times. The 80th percentile of the aggregate is −100.1 dBm, under
the −99 dBm limit, so this radius passes. The limit is met in 89% of
trials.

When the federal site has several protection points, simulation 1 runs for
each point, and the lists are combined. Simulation 2 then checks the combined
list at every point.

One reviewer proposed a single simulation that draws all base stations once
per trial, builds the list from the ones inside the radius, and computes the
aggregate from all the rest, in the same trial. That design uses each trial
twice; the production design checks the list with fresh trials. Which one
gives a different radius, and by how much, is an experiment this paper plans
to run, not a question it can settle by argument
([explainer plan](PLAN_explain_aggregate_zones.md)).

## 10. From a list to a zone

The zone is the smallest radius around the federal site that passes. The
production code finds it with a search:

1. **Try the largest radius.** Run both simulations at the edge of the study
   area. Then try the smallest radius (0 km).
1. **Bisect.** Try the radius halfway between a radius that passes and one
   that fails, and repeat, until the two are no more than the minimum step
   apart (1 km in the production settings).
1. **Record the crossing.** The zone radius is where the aggregate from
   simulation 2 crosses the limit. Every base station inside the zone must
   coordinate; the ones on the turn-off list at that radius are the ones that
   must not transmit as modeled.

The aggregate doesn't always fall smoothly as the radius grows, because each
radius gets its own list. The production code can add a margin in decibels to
the limit (0 dB in the production settings) and has an optional rule for
plateaus when the list is short (turned off in the production settings).

The zone is a circle because the search runs over one number, the distance
from the protection point. A polygon would need a separate radius for each
direction, or a boundary drawn around the base stations on the list. A
polygon can free up area in directions where few base stations contribute,
at the cost of a search in many more dimensions and a zone that is harder to
describe and administer. This paper doesn't take a position on the choice.

The method never draws a boundary around the turn-off list. The zone is the
circle; the list is a set of existing base stations inside it. A base station
that is built later isn't on any list, because the list comes from the
deployment data used in the run. How future base stations inside the zone
are handled, by rerunning the method or by coordination, is a decision for
the working paper, not a result of the simulation.

## 11. Five meanings of "percentage"

The method uses the word *percentage* in five different ways. Most of the
confusion about the method comes from mixing them up:

| Percentage | What it ranges over | Where it is used |
| --- | --- | --- |
| Uniform draw | Nothing physical; a random number between 0 and 1, times 100 | The input to every model (Section 1) |
| Model percentage | Time (ITM), locations (P.2108), or measured cells and periods (EIRP) | Reading each model's curve (Sections 2 to 4) |
| 50th percentile | The same as above, held at the median | Ranking the base stations (Section 8) |
| Monte Carlo percentile | Trials | Sizing the list, and checking the aggregate (Sections 8 and 9) |
| Protection criterion percentage | Time that interference may exceed a level | The requirement the zone must meet |

The last two are easy to confuse. A protection criterion says, for example,
that interference may exceed a level for no more than some percentage of the
time. The Monte Carlo percentile is over trials, and each trial mixes a time,
a location, and an operating state (Section 7). Treating "the 80th
percentile of trials" as "80% of the time" is an assumption, and the paper
that uses the method needs to state it.

### Where the criteria come from, and what a trial can't say

The interference limit is the receiver noise plus the I/N criterion
(Section 13). The I/N value and any percentage of time attached to it come
from a source document, which the working paper needs to cite for each
federal system. Recommendation ITU-R M.1464-2 (02/2015), for example, gives
protection criteria for radars in 2700-2900 MHz. When the source states a
single I/N with no percentage of time, any percentage the analysis adds is a
separate assumption to justify.

Two limits of the method matter here:

- **A trial has no duration.** Each trial is an independent snapshot. The
  simulation can say what fraction of trials exceed a level, but not how long
  an exceedance lasts or how often bursts repeat. A criterion stated in
  seconds of main-beam exposure, or in microsecond bursts, needs a time
  series or a radar model, not these trials.
- **"Long term" and "short term" are labels for the two percentages.** In
  this method they mean only a larger and a smaller allowed exceedance
  percentage. If a federal system's criterion is a single value, there is
  one comparison, not two.

The percentage of trials that exceed the limit is computed directly: count
the trials whose aggregate is above the limit and divide by the number of
trials. Comparing the aggregate at the 80th percentile with the limit is the
same test as asking whether no more than 20% of trials exceed it.

### Comparing against two criteria

When a long-term and a short-term criterion both apply, one set of trials is
compared against both:

- The long-term criterion has a lower interference level that may be exceeded
  for a larger percentage of time. Compare it with a lower Monte Carlo
  percentile (for example, the 80th, for a criterion that may be exceeded
  20% of the time).
- The short-term criterion has a higher level that may be exceeded only
  rarely. Compare it with a high Monte Carlo percentile (for example, the
  99.99th, for a criterion that may be exceeded 0.01% of the time).

The same trials can serve both comparisons. The list is sized for each, and
the larger list applies.

### How many trials a small percentage needs

A percentile is only as good as the number of trials behind it. With 1,000
trials, every percentile above the 99.9th is simply the largest trial: there
is less than one trial in the tail. To estimate the 99.99th percentile with
about 10 trials beyond it, you need about 100,000 trials. The sampling-error
rule in Section 1 gives the uncertainty for any percentile and any number of
trials. A short-term criterion needs either many more trials or a method that
targets the tail directly.

To choose the number of trials, pick the percentile you compare against and
the uncertainty you can accept at it, then solve the standard-error formula
in Section 1 for $n$. As a check, rerun with a different seed: if the zone
radius changes, the number of trials is too small for that percentile. The
production settings use 1,000 trials for the 80th percentile.

## 12. What is random and what is fixed

### Why these distributions

A Monte Carlo simulation is only as good as the distributions it draws from.
None of the three here is invented for the simulation:

| Input | Where its distribution comes from | How this paper checks it |
| --- | --- | --- |
| EIRP | Measured scheduler data from 60 cells, combined with antenna patterns (Section 3) | The fit is within 0.7 dB of every table point (Section 3) |
| Path loss | ITM's time variability, derived from long-term propagation measurements | Reproduces free-space loss on short paths and switches modes at the expected distances (Section 4) |
| Clutter loss | ITU-R P.2108-1 Section 3.2, fitted to measurements in urban and suburban areas | Matches the NTIA reference implementation and its test data (Section 2) |

Each was built for a purpose close to this one: predicting the spread of
power arriving at a distant receiver. The open questions are about fit to
this case, not about the form: the EIRP table comes from a 3.7 GHz network
extrapolated to 7 GHz and used at 2.7 GHz (TODO in Section 3), and clutter
loss doesn't cover every receiver (Section 13).

### Inputs and outputs

| Quantity | Random or fixed | How it varies | Source in this paper |
| --- | --- | --- | --- |
| Base station EIRP | Random | Uniform draw into the EIRP table for the direction toward the receiver | Section 3 |
| Path loss | Random | Uniform draw of ITM time percentage, confidence fixed at 50% | Section 4 |
| Clutter loss | Random | Uniform draw of P.2108 location percentage (production: urban and suburban base stations only) | Section 2 |
| Base station locations, heights, azimuths | Fixed | From the deployment data | Not modeled here |
| Antenna gains toward the receiver | Fixed | From the antenna patterns and geometry | Not modeled here (planned) |
| Frequency-dependent rejection, system loss, polarization loss | Fixed | Set by equipment and frequencies | Section 13 |
| Receiver noise and the protection criterion | Fixed | Set by the federal system | Section 13 |

Every random input gets its own independent draw, for every base station, in
every trial. Everything else is the same in every trial.

The method produces three outputs:

- **The turn-off list** for each candidate radius (simulation 1).
- **Pass or fail** for each candidate radius (simulation 2).
- **The zone radius**, the smallest radius that passes (Section 10).

## 13. Link budget terms

This section defines terms that reviewers asked about, with the arithmetic
that shows when each one matters.

### Receiver noise

The receiver noise power is

$$
N\ (\mathrm{dBm}) = 10\log_{10}(kT) + 10\log_{10}(B) + \mathrm{NF},
$$

with these terms and units:

- $N$: total receiver noise power, in dBm, referred to the receiver input.
- $10\log_{10}(kT)$: the *thermal noise term*, in dBm/Hz. $k$ is Boltzmann's
  constant and $T$ is the noise temperature in kelvin. In general form it is
  $-198.6 + 10\log_{10}(T)$ dBm/Hz.
- $10\log_{10}(B)$: the receiver bandwidth term, in dB relative to 1 Hz. $B$
  is the receiver's noise bandwidth in hertz.
- NF: the receiver noise figure, in dB.

At the standard temperature of 290 K, the thermal noise term is −174 dBm/Hz,
which is the same as −114 dBm/MHz. The two forms give the same answer as long
as $B$ is in the matching unit: hertz with −174, megahertz with −114. A
different temperature changes the thermal noise term by $10\log_{10}(T/290)$
dB. Using 290 K with the receiver noise figure is the usual convention; an
antenna temperature that differs from 290 K, such as a radar looking at a
cold sky, is a separate assumption that needs its own source.

The interference limit follows from the noise: the maximum interference power
is $N$ plus the interference-to-noise ratio (I/N) criterion. For example,
with $B$ = 1 MHz, NF = 5 dB, and an I/N criterion of −10 dB, $N$ is
−109 dBm and the limit is −119 dBm.

### System loss and frequency-dependent rejection

Each base station's interference is reduced by the receiver's system loss and
by frequency-dependent rejection (FDR), which depends on how far the base
station's channel is from the receiver's. The aggregate adds the base
stations in watts:

$$
I_\mathrm{agg} = \sum_i 10^{(P_i - L_\mathrm{sys} - \mathrm{FDR}_i)/10}.
$$

If every base station has the same system loss and the same FDR, both
factors come out of the sum, and you can subtract them once from the
aggregate. If the FDR differs between base stations, because they use
different channels or bandwidths, you must apply it to each base station
before adding. Two base stations show the difference:

| | Base station 1 | Base station 2 | Aggregate |
| --- | --- | --- | --- |
| Received power before FDR | −100 dBm | −103 dBm | −98.2 dBm |
| FDR | 10 dB | 20 dB | |
| Correct: FDR applied to each, then added | −110 dBm | −123 dBm | −109.8 dBm |
| Wrong: a common 10 dB applied after adding | | | −108.2 dBm |

Here the shortcut overstates the aggregate by 1.6 dB. The production
simulation and this paper assume every base station uses the same channel,
so the shortcut is exact; the working paper needs to state that assumption.

### Polarization loss

A base station antenna radiates on two slant polarizations, +45° and −45°.
A receive antenna with one linear polarization (horizontal or vertical)
collects half the power of each slant polarization, which is a 3 dB loss for
each. Two bookkeeping rules follow:

- **Count the EIRP and the loss on the same basis.** If the EIRP is the total
  of both polarizations, subtract 3 dB for a single-polarization receiver. If
  the EIRP is for one polarization, as the CTIA heatmap is (Section 3), a
  single-polarization receiver collects half of each slant, which adds back
  up to the power of one polarization: apply no further loss.
- **A dual-polarized receiver that combines both channels** collects the
  total, with no polarization loss.

At long range, scattering mixes the polarizations. On average, a
single-polarization receiver still collects half the total power, so the
3 dB average holds, but the value in any one trial varies.

### ITM confidence and ground constants

ITM's *confidence* covers the variation among paths that look the same to
the model: unmodeled terrain detail, vegetation, and local surroundings.
Confidence 50% gives the median path. The production simulation and this
paper hold it at 50%. Section 4 shows that moving it to 10% lowers the
median loss on the 100 km path by 7.1 dB, which is why the setting needs to
be stated.

ITM takes the ground's relative permittivity and conductivity as two inputs
and combines them internally into the complex permittivity,
$\varepsilon_r - j\,18\sigma/f_\mathrm{GHz}$. The values used here, 25 and
0.02 S/m, are ITM's "good ground" values. They aren't measured for any site.
Recommendation ITU-R P.527 gives the permittivity of soil, water, and ice by
moisture and frequency; P.2040 covers building materials, which don't apply
to a ground input. The ground constants affect the two-ray region near the
base station and smooth-earth diffraction; they have little effect on a
troposcatter path like the 100 km example. The working paper needs to state
its values and source, and a short sensitivity run settles whether the
choice matters for the zone radius.

### When clutter loss applies

P.2108-1 Section 3.2 gives the extra loss for a terminal inside urban or
suburban clutter. The production simulation applies it only to urban and
suburban base stations. It doesn't cover energy that reaches a receiver by
another route. A weather radar, for example, can receive base station energy
scattered from the precipitation it is observing. That path bypasses the
clutter around the base station and needs separate treatment.

### EIRP level and maximum authorized power

The CTIA table is a measured distribution of 15-minute average power
(Section 3). Some reviewers propose scaling it so that its 100th percentile
equals the maximum authorized EIRP. That shift raises every draw by the same
number of decibels, and the received power and aggregate rise by the same
amount. It also changes what the table means: the top of the distribution
becomes the peak authorized level instead of the highest measured 15-minute
average. This paper treats the choice as a sensitivity case, not a
correction.

### Model versions

| Model | Version used here | Checked |
| --- | --- | --- |
| Clutter loss | Recommendation ITU-R P.2108-1 (09/2021) | November 2026 |
| Path loss | NTIA/ITS Irregular Terrain Model v1.4, through the `matlab_itm` port | November 2026 |
| AAS antenna model behind the EIRP table | Recommendation ITU-R M.2101-0 (02/2017), extended AAS | As cited by the CTIA paper |
| Frequency-dependent rejection | Recommendation ITU-R SM.337-6 | Not used in this paper's examples |
| Interference prediction | Recommendation ITU-R P.452-18 (10/2023) | Not used here; cited for readers comparing models |
| Trans-horizon propagation | Recommendation ITU-R P.617-6 (09/2025) | Not used here; cited for readers comparing models |
| Radar protection criteria, 2700-2900 MHz | Recommendation ITU-R M.1464-2 (02/2015) | Section 11 |

Cite the version in force on the date of the analysis, and give its date.

### Units

Every power in this paper (EIRP, received power, interference, noise) is in
dBm, per megahertz unless the text says otherwise. Every gain and loss is in
dB. A transmit power without an antenna gain is a conducted power and is
also in dBm per megahertz.

## 14. Differences from the production simulation

This paper simplifies the production simulation so that each step is easy to
see. An engineer who compares the two finds these differences:

| Topic | Production simulation | This paper |
| --- | --- | --- |
| Case | 7,250 MHz, a fixed-satellite earth station, with frequency-dependent rejection | 2.7 GHz, a radar receiver (planned), co-channel |
| Draws | A percentage drawn uniformly from 0.001% to 99.999%, the ends of a 47-point grid | A uniform number on (0, 1), times 100 |
| Between grid points | Linear interpolation for path loss and clutter loss; a spline for EIRP | The model itself for path loss and clutter loss; a fitted normal distribution for EIRP |
| Random number seeds | Three draws seeded with `seed+k`, `seed+k+1`, and `seed+k+2` for iteration `k`, so a draw vector reappears in the next iteration for a different input. General_Movelist includes `check_mc_seed_independence_rev1.m` to test this | One stream with a separate substream for each input |
| EIRP level | A fixed median (50.5 dBm/10 MHz) plus the table's offset from its median | The table's values in dBm |
| Clutter loss | Urban and suburban base stations only | Every trial |
| Base station antenna | Horizontal pattern applied by azimuth | Pointed at the receiver |
| Trials | 1,000 Monte Carlo iterations; the 80th percentile is used | 100,000 trials for smooth figures |

Section 2 and Section 4 show that the grid and linear interpolation change
the percentiles by less than 0.1 dB.

## 15. Planned sections

- **A running example.** One synthetic deployment of about 20 base stations
  around one radar site, carried through every step from the inputs to the
  zone radius.
- **Experiments on the method.** Fixed order against per-trial order on a
  larger deployment, one simulation against two, and a time draw shared by
  all base stations in a trial ([explainer
  plan](PLAN_explain_aggregate_zones.md)).
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
1. CTIA, *7 GHz CTIA Cellular Network Characteristics* working paper,
   August 10, 2026.
1. Recommendation ITU-R M.2101-0, *Modelling and simulation of IMT networks
   and systems for use in sharing and compatibility studies*, 02/2017.
1. Recommendation ITU-R SM.337-6, *Frequency and distance separations*,
   10/2008.

## Appendix A. Figure options for the turn-off list

This appendix shows every figure option drawn for Section 8 and the start of
Section 9. Each one tells part of the same worked example in a different form,
so you can pick the one that works for your audience. The
[visualization plan](PLAN_visualize_turn_off_list.md) gives the strengths and
risks of each option.

All numbers come from the exact draws of the example 07 run in Section 8
(1,000 trials, seed 1). The figures are drawn in Python by
`docs/plan_previews/turn_off_list/make_previews.py`, which checks the
published values before it draws. The option ID (A1 to H1) matches the plan.

### Step 1: the ranking

![Option A1: Sorted bars of median received power. Ranks 1 to 6 sit inside the radius; A to D sit outside and can't go on the list.](plan_previews/turn_off_list/png/A1_ranking_bars.png)

*Figure A-1. Option A1. Sorted bars of median received power. Ranks 1 to 6 sit inside the radius; A to D sit outside and can't go on the list.*

![Option A2: Plan-view sketch, not to scale. Dot size shows median power.](plan_previews/turn_off_list/png/A2_plan_view.png)

*Figure A-2. Option A2. Plan-view sketch, not to scale. Dot size shows median power.*

![Option A3: Share of the median aggregate from each base station, as 100 squares. Rank 1 alone delivers 39%.](plan_previews/turn_off_list/png/A3_share_waffle.png)

*Figure A-3. Option A3. Share of the median aggregate from each base station, as 100 squares. Rank 1 alone delivers 39%.*

![Option A4: Share bars with a cumulative line. The first three ranks carry 80% of the median power.](plan_previews/turn_off_list/png/A4_cumulative_share.png)

*Figure A-4. Option A4. Share bars with a cumulative line. The first three ranks carry 80% of the median power.*

### Step 2: one trial, at the medians

![Option B1: The aggregate from the base stations still on, as each one turns off in order. At the medians, the staircase crosses the limit at three off.](plan_previews/turn_off_list/png/B1_staircase.png)

*Figure A-5. Option B1. The aggregate from the base stations still on, as each one turns off in order. At the medians, the staircase crosses the limit at three off.*

![Option B2: The same steps in linear power (femtowatts), where each base station is a block that adds.](plan_previews/turn_off_list/png/B2_shrinking_blocks.png)

*Figure A-6. Option B2. The same steps in linear power (femtowatts), where each base station is a block that adds.*

![Option B3: The same steps as a waterfall: each base station turned off removes its share of the power.](plan_previews/turn_off_list/png/B3_waterfall.png)

*Figure A-7. Option B3. The same steps as a waterfall: each base station turned off removes its share of the power.*

![Option B4: The same steps as a storyboard, one row of tiles per step.](plan_previews/turn_off_list/png/B4_storyboard.png)

*Figure A-8. Option B4. The same steps as a storyboard, one row of tiles per step.*

### Step 2 repeated: many trials

![Option C1: The staircase for the medians and the first three trials. The order is the same in every panel; the cut point moves to 2, 4, and 5.](plan_previews/turn_off_list/png/C1_small_multiples.png)

*Figure A-9. Option C1. The staircase for the medians and the first three trials. The order is the same in every panel; the cut point moves to 2, 4, and 5.*

![Option C2: Staircases for 60 trials, with the medians highlighted. The cut point spreads from 1 to 6.](plan_previews/turn_off_list/png/C2_spaghetti.png)

*Figure A-10. Option C2. Staircases for 60 trials, with the medians highlighted. The cut point spreads from 1 to 6.*

![Option C3: Each rank's received power in 1,000 trials. Rank 2 draws stronger than rank 1 in 38% of trials, but rank 1 still turns off first.](plan_previews/turn_off_list/png/C3_strip_by_rank.png)

*Figure A-11. Option C3. Each rank's received power in 1,000 trials. Rank 2 draws stronger than rank 1 in 38% of trials, but rank 1 still turns off first.*

![Option C4: Received power for the first 12 trials, with the cut drawn as an edge. The off set always starts at rank 1.](plan_previews/turn_off_list/png/C4_heatmap_trials.png)

*Figure A-12. Option C4. Received power for the first 12 trials, with the cut drawn as an edge. The off set always starts at rank 1.*

### The fixed order, made visible

![Option D1: Which base stations turn off in 50 trials, with the fixed median order (left) and if each trial chose its own (right).](plan_previews/turn_off_list/png/D1_tile_grids.png)

*Figure A-13. Option D1. Which base stations turn off in 50 trials, with the fixed median order (left) and if each trial chose its own (right).*

![Option D2: How often each rank turns off, with the fixed order and with free choice.](plan_previews/turn_off_list/png/D2_off_rate_by_rank.png)

*Figure A-14. Option D2. How often each rank turns off, with the fixed order and with free choice.*

![Option D3: The most common sets of base stations that free choice turns off. Free choice produces 56 different sets; the fixed order produces 7.](plan_previews/turn_off_list/png/D3_distinct_lists.png)

*Figure A-15. Option D3. The most common sets of base stations that free choice turns off. Free choice produces 56 different sets; the fixed order produces 7.*

### Steps 3 and 4: from 1,000 cut points to one list size

![Option E1: Quantile dot plot: each dot is 10 trials, rounded by largest remainder. The 80th dot lands at 4; with the margin of one, the list is 5.](plan_previews/turn_off_list/png/E1_quantile_dots.png)

*Figure A-16. Option E1. Quantile dot plot: each dot is 10 trials, rounded by largest remainder. The 80th dot lands at 4; with the margin of one, the list is 5.*

![Option E2: Histogram of the cut points. 83.7% of trials need four or fewer base stations off.](plan_previews/turn_off_list/png/E2_histogram.png)

*Figure A-17. Option E2. Histogram of the cut points. 83.7% of trials need four or fewer base stations off.*

![Option E3: Cumulative share of trials by cut point, with the 80% line.](plan_previews/turn_off_list/png/E3_cumulative.png)

*Figure A-18. Option E3. Cumulative share of trials by cut point, with the 80% line.*

![Option E4: The 80th percentile of the cut points as trials accumulate. It settles at 4 after about 23 trials.](plan_previews/turn_off_list/png/E4_running_percentile.png)

*Figure A-19. Option E4. The 80th percentile of the cut points as trials accumulate. It settles at 4 after about 23 trials.*

### The check (Section 9)

![Option F1: Share of check-run trials exceeding each level. With five off, the aggregate meets the limit in 89% of trials.](plan_previews/turn_off_list/png/F1_exceedance.png)

*Figure A-20. Option F1. Share of check-run trials exceeding each level. With five off, the aggregate meets the limit in 89% of trials.*

![Option F2: Histogram of the check-run aggregate. Its 80th percentile is −100.1 dBm, under the −99 dBm limit.](plan_previews/turn_off_list/png/F2_histogram.png)

*Figure A-21. Option F2. Histogram of the check-run aggregate. Its 80th percentile is −100.1 dBm, under the −99 dBm limit.*

![Option F3: Who stays on in the check run. Base stations outside the radius carry 59% of the median power.](plan_previews/turn_off_list/png/F3_who_stays_on.png)

*Figure A-22. Option F3. Who stays on in the check run. Base stations outside the radius carry 59% of the median power.*

![Option F4: Exceedance curves with all ten on and with the list applied. The list moves the 80th percentile from −89.7 to −100.1 dBm.](plan_previews/turn_off_list/png/F4_before_after.png)

*Figure A-23. Option F4. Exceedance curves with all ten on and with the list applied. The list moves the 80th percentile from −89.7 to −100.1 dBm.*

![Option F5: One dot per check-run trial; the 107 over the limit are purple.](plan_previews/turn_off_list/png/F5_trial_strip.png)

*Figure A-24. Option F5. One dot per check-run trial; the 107 over the limit are purple.*

### What the fixed order costs

![Option G1: Cut points with the fixed order (up) and free choice (down): means of 3.34 and 2.64.](plan_previews/turn_off_list/png/G1_back_to_back.png)

*Figure A-25. Option G1. Cut points with the fixed order (up) and free choice (down): means of 3.34 and 2.64.*

![Option G2: Extra base stations the fixed order turns off compared with each trial's own best set. In 49% of trials it costs nothing extra.](plan_previews/turn_off_list/png/G2_extra_cost.png)

*Figure A-26. Option G2. Extra base stations the fixed order turns off compared with each trial's own best set. In 49% of trials it costs nothing extra.*

### Summary

![Option H1: The four steps in one strip, for slides and read-aheads.](plan_previews/turn_off_list/png/H1_summary_strip.png)

*Figure A-27. Option H1. The four steps in one strip, for slides and read-aheads.*
