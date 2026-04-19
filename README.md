# Falcon 9 kOS Stack

This folder contains the Falcon 9 scripts.

## License

This project uses the restrictive license in `LICENSE.txt`.
Do not publish, reupload, redistribute, or modify and redistribute it without
credit and written permission.
Public showcase videos are allowed if they stay non-monetized and show clear
credit to the original author.

Use it like this:

1. Open the launch pad CPU.
2. Run `boot/Falcon9_LaunchPad_Boot.ks`.
3. The launch pad window opens right away.
4. Set the orbit values you want.
5. Choose the countdown and recovery mode.
6. Press `Start`.
7. Wait for the launch sequence to finish.

## What each script does

- [Falcon9_Main.ks](D:/SteamLibrary/steamapps/common/Kerbal%20Space%20Program/Ships/Script/Falcon9/Falcon9_Main.ks)
  - launch pad control window
  - sets the target orbit
  - sets the countdown
  - starts the launch

- [STAGE_ONE/STAGE_ONE_MAIN.ks](D:/SteamLibrary/steamapps/common/Kerbal%20Space%20Program/Ships/Script/Falcon9/STAGE_ONE/STAGE_ONE_MAIN.ks)
  - controls stage 1 after liftoff
  - follows the ascent pitch and starts the gravity turn earlier
  - handles max-Q throttle down
  - handles MECO
  - handles stage 1 separation

- [STAGE_TWO/STAGE_TWO_MAIN.ks](D:/SteamLibrary/steamapps/common/Kerbal%20Space%20Program/Ships/Script/Falcon9/STAGE_TWO/STAGE_TWO_MAIN.ks)
  - controls stage 2 after separation
  - keeps the vehicle stable
  - ignites stage 2
  - guides the upper stage toward orbit

- [F9_LAZcalc.ks](D:/SteamLibrary/steamapps/common/Kerbal%20Space%20Program/Ships/Script/Falcon9/F9_LAZcalc.ks)
  - launch azimuth helper

- [F9_TRAJECTORY.ks](D:/SteamLibrary/steamapps/common/Kerbal%20Space%20Program/Ships/Script/Falcon9/F9_TRAJECTORY.ks)
  - trajectory graph helper

- [MISSION.ks](D:/SteamLibrary/steamapps/common/Kerbal%20Space%20Program/Ships/Script/Falcon9/MISSION.ks)
  - mission hook used by the boot scripts

## Buttons

- `START`
  - begins the countdown

- `HOLD`
  - pauses the countdown
  - press again to continue

- `RECYCLE`
  - returns to setup
  - keeps your current values

- `DEBUG`
  - opens the in-game kOS terminal

- `MIN`
  - shrinks the window

- `X`
  - closes the window

- `TRAJ ON` / `TRAJ OFF`
  - shows or hides the trajectory graph in stage 1 or stage 2

## Inputs

Set these before launch:

- Apoapsis
- Periapsis
- Inclination
- LAN
- Countdown
- Recovery mode

### Orbit fields

- Apoapsis and periapsis sliders only go up to `1,000 km`.
- The typed boxes can accept up to `300,000 km`.
- Both values cannot be set below the body atmosphere height.
- Inclination is allowed from `-120` to `+120`.

### Recovery mode

- `RTLS`
  - stage 1 shuts down at `25.5%` remaining fuel

- `ASDS`
  - stage 1 shuts down at `18.5%` remaining fuel

## Launch sequence

What happens after `Start`:

1. The countdown runs on the launch pad.
2. At `T-6`, stage 4 ignition is commanded.
3. At pad release, the launch pad checks calculated acceleration.
4. If acceleration is too low, the launch aborts.
5. Stage 1 takes over after liftoff.
6. Stage 1 flies the ascent profile.
7. Stage 1 throttles down through max-Q.
8. Stage 1 shuts down at the chosen recovery fuel percent.
9. Stage 1 waits 3 seconds.
10. Stage 1 separates.
11. Stage 2 takes over.
12. Stage 2 stabilizes, ignites, and guides to orbit.

## Stage timing

- `4` = stage 1 engines
- `3` = launch pad release
- `2` = stage separation
- `1` = fairing halves
- `0` = payload decoupler

## Important notes

- The launch pad window opens automatically.
- You do not need to press `AG6` to open the launch pad GUI.
- `SHIP:NAME` is shown in the top-right of the launch pad window.
- Pressing `Start` clears the old launch handoff state before the new count begins.
- The launch pad shuts down after release so it does not keep running in the background.
- The last values you used are saved and restored next time.
- Trajectory samples are only for the current launch.
- Stage 1 and stage 2 stay hidden until they become active.

## Boot files

These helpers are used by the CPU boot files:

- `boot/Falcon9_LaunchPad_Boot.ks`
- `boot/Falcon9_Stage1_Boot.ks`
- `boot/Falcon9_Stage2_Boot.ks`

## If something goes wrong

- If the window does not appear, make sure the correct boot file is running.
- If the terminal does not open, use the `DEBUG` button.
- If the values look wrong, press `RECYCLE` and set them again.
- If the launch aborts, read the status line in the launch pad window.
