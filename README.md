# 79 kW Battery Management System with CC-CV Charging

A control-oriented MATLAB/Simulink reference implementation of a Battery
Management System (BMS) for a 79 kW battery pack. The model includes
charge/discharge protection, SOC/SOH/SOE/SOP signals, active balancing
request logic, and heating/cooling control.

> **Important:** This is an educational and development reference model. It
> is not a production-ready, automotive-qualified, or safety-certified BMS.
> Do not connect it directly to a real battery pack without a complete
> engineering, safety, validation, and certification process.

## Features

- CC-CV charging permission logic
- Coulomb-counting SOC estimation
- SOH reference signal
- SOE and SOP output signals
- Active cell-balancing request based on cell SOC spread
- Heating request for low-temperature operation
- Cooling request for overtemperature or overcurrent
- Overcharge and overvoltage protection
- Overdischarge and undervoltage protection
- Overcurrent protection
- Charge and discharge enable interlocks
- Reduced-order battery plant for control testing
- Logged Simulink outputs and an example plotting script

## Project files

| File | Description |
| --- | --- |
| `BMS_CC_CV_79kW.slx` | Main Simulink BMS model |
| `run_BMS_CC_CV_79kW.m` | Example simulation and plotting script |
| `BMS_CC_CV_79kW_GUIDE.md` | Detailed implementation and integration guide |

## Model architecture

The model contains two primary subsystems:

### `BatteryPlant`

The reduced-order battery plant estimates:

- Pack voltage
- Battery temperature

It is intended to be replaced with a validated cell or pack model, such as a
Simscape Electrical model, while preserving the subsystem's two output
signals.

### `BMS_Controller`

The controller provides:

- SOC integration
- SOH, SOE, and SOP signals
- Charge permission
- Discharge permission
- Cooling command
- Heating command
- Active balancing status

## Reference assumptions

| Parameter | Reference value |
| --- | ---: |
| Nominal pack voltage | 400 V |
| Power target | 79 kW |
| Current protection limit | 220 A |
| CV/overvoltage cutoff | 420 V |
| Undervoltage cutoff | 280 V |
| Overtemperature limit | 50 °C |
| Heating threshold | 0 °C |
| Minimum SOC | 5% |
| Maximum SOC | 95% |
| Balancing threshold | 2 percentage points |
| Initial SOC | 80% |
| Reference SOH | 95% |

These values are placeholders for simulation. Real limits must be calculated
from the selected cell chemistry, series/parallel configuration, thermal
system, charger, contactors, fuses, wiring, and vehicle requirements.

## Requirements

- MATLAB
- Simulink
- A MATLAB installation capable of opening and simulating `.slx` models

The model uses standard Simulink blocks. A detailed replacement plant may
require additional products, such as Simscape Electrical.

## Quick start

1. Clone or download this repository.
2. Open MATLAB.
3. Change MATLAB's current folder to the repository folder.
4. Open and run the model:

   ```matlab
   open_system('BMS_CC_CV_79kW.slx')
   run('run_BMS_CC_CV_79kW.m')
   ```

The example simulation runs for 3600 seconds. It charges at 150 A, rests,
discharges at 100 A, and applies a 3% cell SOC spread during part of the
charging period to demonstrate the balancing status signal.

The script generates plots for:

- Pack voltage
- SOC
- SOH
- SOE
- SOP
- Charge/discharge/cooling/heating/balancing commands

## External input interface

The model has five root inputs:

| Input | Description |
| --- | --- |
| `PackCurrent_A` | Pack current; positive for charging and negative for discharging |
| `AmbientTemp_C` | Ambient temperature in degrees Celsius |
| `ChargeRequest` | Charge request, `0` or `1` |
| `DischargeRequest` | Discharge request, `0` or `1` |
| `CellDeltaSOC_pct` | Maximum cell SOC minus minimum cell SOC, in percentage points |

For external-input simulation, create a time-based matrix with columns in this
order:

```text
[time, PackCurrent_A, AmbientTemp_C, ChargeRequest, ...
 DischargeRequest, CellDeltaSOC_pct]
```

Then run:

```matlab
simOut = sim('BMS_CC_CV_79kW', ...
    'LoadExternalInput', 'on', ...
    'ExternalInput', myInput, ...
    'ReturnWorkspaceOutputs', 'on');
```

## Protection behavior

Charging is enabled only when all of the following are true:

- `ChargeRequest` is active
- SOC is below 95%
- Pack voltage is below 420 V
- Battery temperature is below 50 °C
- Pack current is below 220 A

Discharging is enabled only when all of the following are true:

- `DischargeRequest` is active
- SOC is above 5%
- Pack voltage is above 280 V
- Battery temperature is below 50 °C
- Pack current is below 220 A

Cooling is requested when the battery is overtemperature or overcurrent.
Heating is requested below 0 °C when the ambient temperature is low.
Balancing is requested when `CellDeltaSOC_pct` is greater than 2%.

The CC-CV behavior is represented by current-limited charging together with
voltage and SOC cutoffs. A charger-facing implementation should replace the
charge permission with a current reference that maintains constant current
below the CV threshold and tapers current while holding the pack at the CV
voltage.

## Output signals

The model logs the following outputs in `simOut.yout`:

- `PackVoltage_V`
- `SOC_pct`
- `SOH_pct`
- `SOE_pct`
- `SOP_pct`
- `ChargeEnable`
- `DischargeEnable`
- `CoolingCmd`
- `HeatingCmd`
- `BalanceStatus`

Example:

```matlab
soc = simOut.yout{2}.Values;
plot(soc.Time, soc.Data);
grid on;
xlabel('Time (s)');
ylabel('SOC (%)');
```

## Replacing the battery plant

Replace the contents of `BatteryPlant` with a validated cell or pack model.
Keep its two outputs:

1. Pack voltage in volts
2. Battery temperature in degrees Celsius

For cell-level active balancing, calculate the maximum-minus-minimum cell SOC
spread and provide it through `CellDeltaSOC_pct`. The reference model exposes a
balancing status signal; a hardware-oriented implementation must replace this
with individual cell balancing switch or bleed-current commands.

## Validation and safety checklist

Before using this model with hardware or a detailed plant:

- Validate the current sign convention and battery capacity used for SOC.
- Replace the fixed SOH value with a capacity and resistance estimator.
- Add cell-level maximum/minimum voltage monitoring.
- Add redundant voltage, current, and temperature sensing.
- Implement contactor control, precharge, weld detection, fusing, and isolation
  monitoring.
- Test open-circuit, short-circuit, stuck-at, communication-loss, and watchdog
  faults.
- Perform parameter sweeps and MIL/SIL/HIL testing.
- Perform thermal runaway, abuse, and fault-containment analysis.
- Verify all thresholds against the applicable battery and vehicle standards.

## License

No license has been specified for this repository. Add an appropriate
`LICENSE` file before distributing the project publicly.
