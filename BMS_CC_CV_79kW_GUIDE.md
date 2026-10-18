# 79 kW BMS reference model

Files:

- `BMS_CC_CV_79kW.slx` - Simulink model.
- `run_BMS_CC_CV_79kW.m` - repeatable simulation and plotting script.

## Scope and assumptions

This is a runnable control-oriented reference model, not a production battery
pack or a certified safety controller. The battery plant is intentionally
reduced-order so that the BMS logic can be inspected and replaced with a
detailed Simscape Electrical cell model later.

The reference pack assumptions are:

- 400 V nominal pack voltage.
- 79 kW maximum power target, represented by a 220 A current protection limit.
- 420 V overvoltage / CV cutoff threshold.
- 280 V undervoltage threshold.
- 50 degC overtemperature threshold.
- 0 degC low-temperature heating threshold.
- 5% and 95% SOC operating limits.
- 2 percentage points cell-to-cell SOC spread threshold for balancing.
- Initial SOC = 80%, fixed reference SOH = 95%.

For a real pack, derive voltage, current, thermal and energy limits from the
selected cells, series/parallel configuration, contactors, fuses, cooling
system, charger and vehicle requirements. Do not use this reference model as
the sole protection layer for hardware.

## Architecture

At the top level:

- `BatteryPlant` estimates pack voltage and battery temperature from current
  and ambient temperature.
- `BMS_Controller` contains SOC integration, SOH/SOE/SOP signals, CC/CV
  charge permission, discharge permission, thermal commands and balancing.
- Root outputs expose pack voltage, SOC, SOH, SOE, SOP, charge/discharge
  enables, cooling/heating commands and `BalanceStatus`.

Protection behavior:

- Charging is enabled only when `ChargeRequest` is high, SOC is below 95%,
  voltage is below 420 V, temperature is below 50 degC and current is below
  220 A.
- Discharging is enabled only when `DischargeRequest` is high, SOC is above
  5%, voltage is above 280 V, temperature is below 50 degC and current is
  below 220 A.
- Cooling is requested for overtemperature or overcurrent.
- Heating is requested below 0 degC while the ambient-temperature input is
  low.
- Balancing is requested when `CellDeltaSOC_pct` is greater than 2%.

The CC/CV behavior is represented by the current-limited charge request and
the voltage/SOC cutoff. For a charger-facing implementation, replace the
charge permission signal with a current reference that holds constant current
below the CV threshold and tapers current while holding pack voltage at the
CV threshold.

## Run in MATLAB/Simulink

1. Open MATLAB and change to the folder containing the two files.
2. Open the model:

   ```matlab
   open_system('BMS_CC_CV_79kW.slx')
   ```

3. Run the supplied example:

   ```matlab
   run('run_BMS_CC_CV_79kW.m')
   ```

4. Inspect the model scopes and the generated figure. The test profile
   charges at 150 A, rests, discharges at 100 A and applies a 3% cell SOC
   spread during part of charging.

## External input contract

The model has five root inputs, in this order:

1. `PackCurrent_A` - positive for charging and negative for discharging.
2. `AmbientTemp_C`.
3. `ChargeRequest` - 0 or 1.
4. `DischargeRequest` - 0 or 1.
5. `CellDeltaSOC_pct` - maximum-minus-minimum cell SOC spread in percentage
   points.

For external-input simulation, provide a time matrix with columns
`[time, PackCurrent_A, AmbientTemp_C, ChargeRequest, DischargeRequest,
CellDeltaSOC_pct]`, then call:

```matlab
simOut = sim('BMS_CC_CV_79kW', ...
    'LoadExternalInput', 'on', ...
    'ExternalInput', 'myInput', ...
    'ReturnWorkspaceOutputs', 'on');
```

The saved output dataset is `simOut.yout`. For example:

```matlab
soc = simOut.yout.getElement('SOC_pct').Values;
plot(soc.Time, soc.Data);
grid on;
```

## Replacing the reduced-order plant

Replace the contents of `BatteryPlant` with a validated cell/pack model.
Preserve its two outputs:

1. Pack voltage in volts.
2. Battery temperature in degrees Celsius.

The BMS controller can then remain connected to the replacement plant. For
cell-level balancing, feed the measured maximum-minus-minimum cell SOC into
`CellDeltaSOC_pct` and replace the `BalanceStatus` signal with balancing
switch/bleed-current commands for each cell.

## Safety and validation checklist

Before using a detailed model or hardware:

- Validate current sign convention and SOC coulomb-counting capacity.
- Replace fixed SOH with an estimator based on capacity and resistance tests.
- Implement a cell-level maximum/minimum voltage monitor.
- Add redundant voltage, current and temperature sensing.
- Add contactor precharge, weld detection, fuse coordination and isolation
  monitoring.
- Test sensor-open, sensor-short, stuck-at, communication-loss and watchdog
  faults.
- Verify limits with parameter sweeps and MIL/SIL/HIL testing.
- Perform thermal runaway, abuse and fault-containment analysis separately.
