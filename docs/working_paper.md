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

$$
P_\mathrm{rx}\ (\mathrm{dBm}) = \mathrm{EIRP} - L_\mathrm{path} - L_\mathrm{clutter} + G_\mathrm{antennas}
$$

Each term on the right except the antenna gains is a separate draw.

Sections 6 and 7 do this for one base station. Section 8 lists the planned
sections on how per-station powers are added and how the turn-off list is
built.

## 2. Example 1: clutter loss (ITU-R P.2108-1), 2 km, 2.7 GHz

**Code:** `examples/example_01_p2108_2km_2700mhz_rev1.m`,
`src/p2108_terrestrial_clutter_loss_vector_rev2.m`

### The model

Recommendation ITU-R P.2108-1 (09/2021), Annex 1, Section 3.2, gives the
clutter loss for a terminal inside urban or suburban clutter. It is the
current version of the Recommendation. For frequency *f* (GHz), path length
*d* (km), and location percentage *p*:

| Equation | Expression |
| ---- | -------------------------------------------------------------------------- |
| (4a) | $L_\mathrm{l} = -2\log_{10}\left(10^{-5\log_{10}(f) - 12.5} + 10^{-16.5}\right)$ |
| (5a) | $L_\mathrm{s} = 32.98 + 23.9\log_{10}(d) + 3\log_{10}(f)$ |
| (3b) | $\sigma_\mathrm{cb} = \sqrt{\dfrac{\sigma_\mathrm{l}^2\,10^{-0.2 L_\mathrm{l}} + \sigma_\mathrm{s}^2\,10^{-0.2 L_\mathrm{s}}}{10^{-0.2 L_\mathrm{l}} + 10^{-0.2 L_\mathrm{s}}}}$ |
| (4b), (5b) | $\sigma_\mathrm{l} = 4$ dB, $\sigma_\mathrm{s} = 6$ dB |
| (3a) | $L_\mathrm{ctt} = -5\log_{10}\left(10^{-0.2 L_\mathrm{l}} + 10^{-0.2 L_\mathrm{s}}\right) - \sigma_\mathrm{cb}\,Q^{-1}(p/100)$ |
| (6) | $L_\mathrm{ctt}$ may not exceed the value computed for *d* = 2 km |

$Q^{-1}$ is the inverse complementary normal distribution function.
The model covers 0.5 to 67 GHz and paths of at least 0.25 km (1 km when the
correction is applied at both ends).

Equation (3a) is a median term minus $\sigma_\mathrm{cb}$ times a standard normal
quantile. In other words, **P.2108 clutter loss is a normal distribution in
dB**, and (3a) is its inverse CDF.

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

*Figure 1. Left: 100,000 uniform draws. Center: the P.2108 curve that maps a
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
  vector is 42.8 dB. The largest difference found is 2.0 dB (1.6 GHz, 0.5 km,
  *p* = 99.9). At *p* ≤ 50, and at 2 km and beyond, there is no difference, so
  the worked example here is unaffected.
- **Output shape.** The documented shape, distances by percentages, now holds
  for row and matrix distance inputs.

`_rev2` passes all seven NTIA test vectors. One behavior is a project
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
FSS_Neighborhood). Values are in dBm.

**Where the table comes from.** CTIA provided the table, based on empirical
measurements of base stations in the field. It is measured data, not the
output of an antenna model.

| Percentile (%) | EIRP (dBm) | Offset from median (dB) |
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
column per percentile. The production simulation can take either one.

The two differ in what a percentile means. In the modeled table a percentile
is over random beam pointings; it includes no traffic load or TDD activity
unless those are added. A table from field measurements reflects how the
measured base stations actually operated.

**Assumption to confirm.** The table comes from the 7 GHz work. Using it here
assumes that the shape of the EIRP distribution, its spread around the median,
carries over to base stations at 2.7 GHz. (TODO: confirm, or replace with
2.7 GHz data.)

### From 11 points to a smooth distribution

The table gives only 11 points of the distribution. Drawing from it needs a
rule for the values between the points. Two rules give different shapes:

- **A spline through the points.** The production simulation does this. The
  table is flattest between the 30th and 40th and between the 60th and 70th
  percentiles, so the spline maps many percentages to nearly the same EIRP.
  The draws then pile up in two peaks that come from the interpolation, not
  from how base stations operate.
- **A fitted normal distribution in dBm.** This paper uses this rule. It fits
  a normal distribution to the table's percentiles and cuts it off at the
  table's 0th and 100th percentiles (19.5 dBm and 42.5 dBm), so no draw falls
  outside the measured range. A normal distribution in dB is a lognormal
  distribution in watts, the usual model for power that varies by many
  small effects multiplied together.

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
of 0.35 dB.

### Uniform in, EIRP out

![Base station EIRP from the fitted normal distribution](figures/fig02_bs_eirp_distribution.png)

*Figure 2. Left: 100,000 uniform draws. Center: the fitted distribution's
inverse CDF (line) and the CTIA table (circles). Right: the EIRP draws, a
single bell-shaped peak.*

Things to notice:

- The draws have one peak, at the median, and fall off on both sides.
- 98% of draws fall within 20.4 dB: from 21.1 dBm (1st percentile) to
  41.5 dBm (99th percentile).
- Choosing the fit over the spline changes the received power in Section 6 by
  at most 0.4 dB at any listed percentile. The choice changes the picture, not
  the result.

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
| Surface refractivity $N_0$ | 301 N-units |
| Polarization | Vertical |
| Ground | ε = 25, σ = 0.02 S/m |
| Mode of variability | 13 (broadcast, no location variability) |

On this path the two radio horizons are 22.6 km and 13.0 km from the
terminals, well short of meeting, so ITM reports the troposcatter mode.
Free-space loss is 141.08 dB. ITM's reference attenuation adds 58.97 dB.

### Uniform in, path loss out

![ITM loss on a flat 100 km path at 2.7 GHz](figures/fig03_itm_flat_100km_2700mhz.png)

*Figure 3. Left: 100,000 uniform draws. Center: ITM loss against the time
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
| EIRP | Normal fit to the CTIA table | Operating states | 31.68 dBm | 20.4 dB |
| Path loss, flat 100 km | ITM v1.4 | Time | 197.13 dB | 39.2 dB |

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
1. Adds the three values in dB.

The receive antenna gain is 0 dBi. The radar antenna comes in a later section.

### Three distributions in, one distribution out

![Received power from one base station at 100 km](figures/fig04_single_bs_100km_2700mhz.png)

*Figure 4. Top: the three input distributions from 100,000 trials. Bottom
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

- **Exact convolution.** Because the three inputs are independent, the
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

*Figure 5. Left: the range of received power with all three inputs varying
(top) and with each input held at its median. Thick bars cover 5% to 95% of
trials, thin lines 1% to 99%, circles mark the median. The diamond marks the
worst-case stack. Right: each input's share of the variance of the received
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
  20.3 dB. Holding EIRP or clutter loss fixed narrows it by only 3 dB or
  less.
- **Spreads add as variances, not as decibels.** The standard deviations of
  the inputs are 8.20 dB, 4.66 dB, and 4.02 dB. They add to 16.9 dB, but the
  output standard deviation is 10.24 dB, close to the square root of the sum of
  their squares (10.26 dB). Independent inputs partly cancel each other's extremes.
- **Worst cases don't stack.** Taking the worst 1% of each input together
  (99th percentile EIRP, 1st percentile path loss, 1st percentile clutter
  loss) gives −152.8 dBm. The 99th percentile of the actual sum is
  −168.3 dBm, 15.4 dB lower. All three inputs are almost never at their
  extremes in the same trial. A worst-case stack overstates the interference
  that one base station causes 1% of the time by about 15 dB.
- **Effort on the inputs should follow the variance.** A better path loss
  model, with real terrain and a confidence level chosen with care, changes
  the answer far more than refining the EIRP table or the clutter model.

## 8. Planned sections

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
