@LAZYGLOBAL OFF.

// Falcon 9 launch pad console.
// This is the only operational role for the first step.

RUNPATH("0:/Falcon9/MISSION.ks").

GLOBAL F9_SETTINGS_ARCHIVE IS "0:/Falcon9/MISSION.ks".
GLOBAL F9_SETTINGS_VOLUME IS "/Falcon9/MISSION.ks".
GLOBAL F9_MISSION_STATE_PATH IS "0:/Falcon9/MISSION_STATE.json".

GLOBAL F9_GUI_WIDTH IS 640.
GLOBAL F9_GUI_HEIGHT IS 470.
GLOBAL F9_GUI_MIN_HEIGHT IS 72.
GLOBAL F9_GUI_X IS 210.
GLOBAL F9_GUI_Y IS 640.

GLOBAL F9_DEFAULT_TITLE IS "FALCON 9 LAUNCH PAD CONTROL".
GLOBAL F9_DEFAULT_SUBTITLE IS "LAUNCH PAD COUNTDOWN CONSOLE".
GLOBAL F9_DEFAULT_MISSION_NAME IS "FALCON 9".
GLOBAL F9_DEFAULT_COUNTDOWN_SECONDS IS 360.
GLOBAL F9_DEFAULT_APOAPSIS_KM IS 80.
GLOBAL F9_DEFAULT_PERIAPSIS_KM IS 80.
GLOBAL F9_DEFAULT_INCLINATION_DEG IS 0.
GLOBAL F9_DEFAULT_LAN_DEG IS 0.
GLOBAL F9_DEFAULT_RECOVERY_METHOD IS "RTLS".
GLOBAL F9_DEFAULT_MECO_FUEL_PERCENT IS 25.5.
GLOBAL F9_KSP_DAY_SECONDS IS 21600.
GLOBAL F9_IGNITION_T_MINUS IS 6.
GLOBAL F9_STAGE_ENGINE_STAGE IS 4.
GLOBAL F9_STAGE_STRONGBACK_RELEASE_STAGE IS 3.
GLOBAL F9_STAGE_SEPARATION_STAGE IS 2.
GLOBAL F9_STAGE_FAIRING_STAGE IS 1.
GLOBAL F9_STAGE_PAYLOAD_DECOUPLER_STAGE IS 0.
GLOBAL F9_MIN_STAGE1_FUEL_UNITS IS 1.
GLOBAL F9_COUNTDOWN_PRESETS IS LIST(
    "00:00:30",
    "00:01:00",
    "00:02:00",
    "00:03:00",
    "00:04:00",
    "00:05:00",
    "00:06:00",
    "00:10:00",
    "00:15:00",
    "00:20:00"
).

GLOBAL F9_SETTINGS IS LEXICON().
GLOBAL F9_RUNTIME IS LEXICON(
    "mode", "SETUP",
    "running", FALSE,
    "held", FALSE,
    "countdown_seconds", F9_DEFAULT_COUNTDOWN_SECONDS,
    "selected_countdown_seconds", F9_DEFAULT_COUNTDOWN_SECONDS,
    "target_apoapsis_km", F9_DEFAULT_APOAPSIS_KM,
    "target_periapsis_km", F9_DEFAULT_PERIAPSIS_KM,
    "target_inclination_deg", F9_DEFAULT_INCLINATION_DEG,
    "target_lan_deg", F9_DEFAULT_LAN_DEG,
    "recovery_method", F9_DEFAULT_RECOVERY_METHOD,
    "meco_fuel_percent", F9_DEFAULT_MECO_FUEL_PERCENT,
    "next_tick_at", -1,
    "status_text", "READY",
    "ui_dirty", TRUE,
    "minimized", FALSE,
    "ui_closed", FALSE,
    "launch_phase", "IDLE",
    "launch_abort_reason", ""
).

GLOBAL f9_gui IS 0.
GLOBAL f9_title_label IS 0.
GLOBAL f9_mission_label IS 0.
GLOBAL f9_mode_label IS 0.
GLOBAL f9_timer_label IS 0.
GLOBAL f9_selected_label IS 0.
GLOBAL f9_status_label IS 0.
GLOBAL f9_file_label IS 0.
GLOBAL f9_input_box IS 0.
GLOBAL f9_orbit_box IS 0.
GLOBAL f9_countdown_box IS 0.
GLOBAL f9_apo_slider IS 0.
GLOBAL f9_apo_value_label IS 0.
GLOBAL f9_apo_textfield IS 0.
GLOBAL f9_peri_slider IS 0.
GLOBAL f9_peri_value_label IS 0.
GLOBAL f9_peri_textfield IS 0.
GLOBAL f9_inclination_slider IS 0.
GLOBAL f9_inclination_value_label IS 0.
GLOBAL f9_inclination_textfield IS 0.
GLOBAL f9_lan_slider IS 0.
GLOBAL f9_lan_value_label IS 0.
GLOBAL f9_lan_textfield IS 0.
GLOBAL f9_recovery_menu IS 0.
GLOBAL f9_recovery_value_label IS 0.
GLOBAL f9_countdown_menu IS 0.
GLOBAL f9_countdown_value_label IS 0.
GLOBAL f9_start_button IS 0.
GLOBAL f9_hold_button IS 0.
GLOBAL f9_recycle_button IS 0.
GLOBAL f9_debug_button IS 0.
GLOBAL f9_minimize_button IS 0.
GLOBAL f9_close_button IS 0.

CLEARGUIS().
LoadFalcon9Settings().
BuildFalcon9Gui().
SyncFalcon9Gui(TRUE).
RunFalcon9Console().

FUNCTION ReadFalcon9Settings {
    IF EXISTS(F9_MISSION_STATE_PATH) {
        RETURN READJSON(F9_MISSION_STATE_PATH).
    }.

    RUNPATH(F9_SETTINGS_ARCHIVE).
    RETURN GetFalcon9MissionConfiguration().
}.

FUNCTION LoadFalcon9Settings {
    LOCAL settingsRecord TO ReadFalcon9Settings().

    SET F9_SETTINGS TO settingsRecord.
    SET F9_RUNTIME["selected_countdown_seconds"] TO GetSettingOrDefault(settingsRecord, "selected_countdown_seconds", GetSettingOrDefault(settingsRecord, "default_countdown_seconds", F9_DEFAULT_COUNTDOWN_SECONDS)).
    SET F9_RUNTIME["countdown_seconds"] TO F9_RUNTIME["selected_countdown_seconds"].
    SET F9_RUNTIME["target_apoapsis_km"] TO ClampOrbitAltitudeKm(GetSettingOrDefault(settingsRecord, "target_apoapsis_km", F9_DEFAULT_APOAPSIS_KM)).
    SET F9_RUNTIME["target_periapsis_km"] TO ClampOrbitAltitudeKm(GetSettingOrDefault(settingsRecord, "target_periapsis_km", F9_DEFAULT_PERIAPSIS_KM)).
    SET F9_RUNTIME["target_inclination_deg"] TO GetSettingOrDefault(settingsRecord, "target_inclination_deg", F9_DEFAULT_INCLINATION_DEG).
    SET F9_RUNTIME["target_lan_deg"] TO GetSettingOrDefault(settingsRecord, "target_lan_deg", F9_DEFAULT_LAN_DEG).
    SET F9_RUNTIME["recovery_method"] TO GetSettingOrDefault(settingsRecord, "recovery_method", F9_DEFAULT_RECOVERY_METHOD).
    SET F9_RUNTIME["meco_fuel_percent"] TO GetRecoveryMecoFuelPercent(F9_RUNTIME["recovery_method"]).
    SET F9_RUNTIME["mode"] TO "SETUP".
    SET F9_RUNTIME["running"] TO FALSE.
    SET F9_RUNTIME["held"] TO FALSE.
    SET F9_RUNTIME["next_tick_at"] TO -1.
    SET F9_RUNTIME["status_text"] TO "READY".
    SET F9_RUNTIME["launch_phase"] TO "IDLE".
    SET F9_RUNTIME["launch_abort_reason"] TO "".
}.

FUNCTION SaveFalcon9MissionState {
    LOCAL missionState TO LEXICON().

    IF EXISTS(F9_MISSION_STATE_PATH) {
        SET missionState TO READJSON(F9_MISSION_STATE_PATH).
    }.

    SET missionState["default_countdown_seconds"] TO F9_RUNTIME["selected_countdown_seconds"].
    SET missionState["selected_countdown_seconds"] TO F9_RUNTIME["selected_countdown_seconds"].
    SET missionState["target_apoapsis_km"] TO F9_RUNTIME["target_apoapsis_km"].
    SET missionState["target_periapsis_km"] TO F9_RUNTIME["target_periapsis_km"].
    SET missionState["target_inclination_deg"] TO F9_RUNTIME["target_inclination_deg"].
    SET missionState["target_lan_deg"] TO F9_RUNTIME["target_lan_deg"].
    SET missionState["recovery_method"] TO F9_RUNTIME["recovery_method"].
    SET missionState["meco_fuel_percent"] TO F9_RUNTIME["meco_fuel_percent"].

    WRITEJSON(missionState, F9_MISSION_STATE_PATH).
}.

FUNCTION ResetFalcon9LaunchState {
    LOCAL missionState TO LEXICON().

    IF EXISTS(F9_MISSION_STATE_PATH) {
        SET missionState TO READJSON(F9_MISSION_STATE_PATH).
    }.

    SET missionState["trajectory_samples"] TO LIST().
    SET missionState["trajectory_origin_lat"] TO SHIP:LATITUDE.
    SET missionState["trajectory_origin_lng"] TO SHIP:LONGITUDE.
    SET missionState["last_sample_time"] TO -9999.
    SET missionState["stage_fuel_start_units"] TO 0.
    SET missionState["meco_reached"] TO FALSE.
    SET missionState["throttle_armed"] TO FALSE.
    SET missionState["qbucket_active"] TO FALSE.
    SET missionState["max_q_peak"] TO 0.
    SET missionState["stabilizing"] TO FALSE.
    SET missionState["handoff_phase"] TO "IDLE".

    WRITEJSON(missionState, F9_MISSION_STATE_PATH).
}.

FUNCTION ResetFalcon9TrajectoryState {
    ResetFalcon9LaunchState().
}.

FUNCTION GetSettingOrDefault {
    PARAMETER record, key, defaultValue.

    IF record:HASKEY(key) {
        RETURN record[key].
    }.

    RETURN defaultValue.
}.

FUNCTION FormatSecondsAsClock {
    PARAMETER totalSeconds.

    LOCAL safeSeconds TO MAX(0, ROUND(totalSeconds, 0)).
    LOCAL hours TO FLOOR(safeSeconds / 3600).
    LOCAL minutes TO FLOOR((safeSeconds - hours * 3600) / 60).
    LOCAL seconds TO safeSeconds - (hours * 3600) - (minutes * 60).
    LOCAL hourText TO "" + hours.
    LOCAL minuteText TO "" + minutes.
    LOCAL secondText TO "" + seconds.

    IF hours < 10 {
        SET hourText TO "0" + hourText.
    }.

    IF minutes < 10 {
        SET minuteText TO "0" + minuteText.
    }.

    IF seconds < 10 {
        SET secondText TO "0" + secondText.
    }.

    RETURN hourText + ":" + minuteText + ":" + secondText.
}.

FUNCTION FormatKilometers {
    PARAMETER value.

    RETURN "" + ROUND(value, 0) + " km".
}.

FUNCTION FormatDegrees {
    PARAMETER value.

    RETURN "" + (ROUND(value * 10, 0) / 10) + " deg".
}.

FUNCTION GetAtmosphericFloorKm {
    IF NOT SHIP:BODY:ATM:EXISTS {
        RETURN 0.
    }.

    RETURN FLOOR(SHIP:BODY:ATM:HEIGHT / 1000).
}.

FUNCTION ClampOrbitAltitudeKm {
    PARAMETER value.

    RETURN ClampNumber(value, GetAtmosphericFloorKm(), 300000).
}.

FUNCTION SyncOrbitControlsToFloor {
    LOCAL floorKm TO GetAtmosphericFloorKm().

    IF f9_apo_slider <> 0 {
        SET f9_apo_slider:MIN TO floorKm.
    }.

    IF f9_peri_slider <> 0 {
        SET f9_peri_slider:MIN TO floorKm.
    }.

    SET F9_RUNTIME["target_apoapsis_km"] TO ClampOrbitAltitudeKm(F9_RUNTIME["target_apoapsis_km"]).
    SET F9_RUNTIME["target_periapsis_km"] TO ClampOrbitAltitudeKm(F9_RUNTIME["target_periapsis_km"]).

    IF f9_apo_slider <> 0 {
        SET f9_apo_slider:VALUE TO F9_RUNTIME["target_apoapsis_km"].
    }.

    IF f9_peri_slider <> 0 {
        SET f9_peri_slider:VALUE TO F9_RUNTIME["target_periapsis_km"].
    }.

    IF f9_apo_textfield <> 0 {
        SET f9_apo_textfield:TEXT TO "" + F9_RUNTIME["target_apoapsis_km"].
    }.

    IF f9_peri_textfield <> 0 {
        SET f9_peri_textfield:TEXT TO "" + F9_RUNTIME["target_periapsis_km"].
    }.

    IF f9_apo_value_label <> 0 {
        SET f9_apo_value_label:TEXT TO FormatKilometers(F9_RUNTIME["target_apoapsis_km"]).
    }.

    IF f9_peri_value_label <> 0 {
        SET f9_peri_value_label:TEXT TO FormatKilometers(F9_RUNTIME["target_periapsis_km"]).
    }.
}.

FUNCTION SetFalcon9WindowState {
    PARAMETER minimized.

    SET F9_RUNTIME["minimized"] TO minimized.

    IF minimized {
        f9_subtitle_label:HIDE().
        f9_mission_label:HIDE().
        f9_status_box:HIDE().
        f9_file_label:HIDE().
        f9_input_box:HIDE().
        SET f9_gui:STYLE:HEIGHT TO F9_GUI_MIN_HEIGHT.
        SET f9_minimize_button:TEXT TO "RESTORE".
    } ELSE {
        f9_subtitle_label:SHOW().
        f9_mission_label:SHOW().
        f9_status_box:SHOW().
        f9_file_label:SHOW().
        f9_input_box:SHOW().
        SET f9_gui:STYLE:HEIGHT TO F9_GUI_HEIGHT.
        SET f9_minimize_button:TEXT TO "MIN".
    }.

    SET F9_RUNTIME["ui_dirty"] TO TRUE.
}.

FUNCTION ClampNumber {
    PARAMETER value, minValue, maxValue.

    IF value < minValue {
        RETURN minValue.
    }.

    IF value > maxValue {
        RETURN maxValue.
    }.

    RETURN value.
}.

FUNCTION GetLaunchAcceleration {
    IF SHIP:MASS <= 0 {
        RETURN -1.
    }.

    RETURN SHIP:AVAILABLETHRUST / SHIP:MASS.
}.

FUNCTION GetShipDeltaVCurrent {
    IF NOT SHIP:HASSUFFIX("DELTAV") {
        RETURN -1.
    }.

    SHIP:DELTAV:FORCECALC().
    RETURN SHIP:DELTAV:CURRENT.
}.

FUNCTION GetShipResourceAmount {
    PARAMETER resourceName.

    LOCAL amount TO 0.

    FOR resourceEntry IN SHIP:RESOURCES {
        IF resourceEntry:NAME = resourceName {
            SET amount TO amount + resourceEntry:AMOUNT.
        }.
    }.

    RETURN amount.
}.

FUNCTION GetStageResourceAmount {
    PARAMETER resourceName.

    LOCAL amount TO 0.

    FOR resourceEntry IN STAGE:RESOURCES {
        IF resourceEntry:NAME = resourceName {
            SET amount TO amount + resourceEntry:AMOUNT.
        }.
    }.

    RETURN amount.
}.

FUNCTION GetLaunchResourceSnapshot {
    LOCAL liquidFuel TO GetShipResourceAmount("LIQUIDFUEL").
    LOCAL oxidizer TO GetShipResourceAmount("OXIDIZER").
    LOCAL totalDv TO GetShipDeltaVCurrent().
    LOCAL stageDv TO -1.

    IF SHIP:HASSUFFIX("STAGEDELTAV") {
        SET stageDv TO SHIP:STAGEDELTAV(F9_STAGE_ENGINE_STAGE):CURRENT.
    }.

    RETURN LEXICON(
        "total_dv", totalDv,
        "stage_dv", stageDv,
        "accel", GetLaunchAcceleration(),
        "stage_number", STAGE:NUMBER,
        "liquid_fuel", liquidFuel,
        "oxidizer", oxidizer,
        "stage_fuel", liquidFuel + oxidizer
    ).
}.

FUNCTION CheckFalcon9LaunchGates {
    LOCAL snapshot TO GetLaunchResourceSnapshot().

    IF snapshot["stage_fuel"] < F9_MIN_STAGE1_FUEL_UNITS {
        RETURN "STAGE 1 FUEL LOW".
    }.

    RETURN "".
}.

FUNCTION AbortFalcon9Launch {
    PARAMETER reason.

    LOCK THROTTLE TO 0.
    UNLOCK STEERING.
    SET F9_RUNTIME["running"] TO FALSE.
    SET F9_RUNTIME["held"] TO FALSE.
    SET F9_RUNTIME["mode"] TO "ABORTED".
    SET F9_RUNTIME["launch_phase"] TO "ABORTED".
    SET F9_RUNTIME["launch_abort_reason"] TO reason.
    SET F9_RUNTIME["status_text"] TO "ABORT: " + reason.
    SET F9_RUNTIME["next_tick_at"] TO -1.
    SET F9_RUNTIME["ui_dirty"] TO TRUE.

    SET f9_hold_button:PRESSED TO FALSE.
    SET f9_hold_button:TEXT TO "HOLD".
}.

FUNCTION IgniteFalcon9FirstStage {
    IF F9_RUNTIME["launch_phase"] <> "COUNTDOWN" {
        RETURN.
    }.

    RCS OFF.
    LOCAL gateReason TO CheckFalcon9LaunchGates().
    IF gateReason <> "" {
        AbortFalcon9Launch(gateReason).
        RETURN.
    }.

    IF NOT STAGE:READY {
        AbortFalcon9Launch("STAGE NOT READY").
        RETURN.
    }.

    LOCK THROTTLE TO 1.
    LOCK STEERING TO UP.
    STAGE.
    WAIT 0.

    SET F9_RUNTIME["launch_phase"] TO "IGNITED".
    SET F9_RUNTIME["status_text"] TO "STAGE 4 IGNITED / HOLDING FOR RELEASE".
    SET F9_RUNTIME["ui_dirty"] TO TRUE.
}.

FUNCTION ReleaseFalcon9FromPad {
    IF F9_RUNTIME["launch_phase"] <> "IGNITED" {
        RETURN.
    }.

    RCS OFF.
    LOCAL releaseDeadline TO TIME:SECONDS + 1.
    UNTIL STAGE:READY {
        IF TIME:SECONDS > releaseDeadline {
            AbortFalcon9Launch("PAD RELEASE NOT READY").
            RETURN.
        }.
        WAIT 0.1.
    }.

    LOCAL snapshot TO GetLaunchResourceSnapshot().
    IF snapshot["accel"] < 1.9 {
        AbortFalcon9Launch("ACCEL BELOW 1.9 M/S2 AT RELEASE").
        RETURN.
    }.

    STAGE.
    WAIT 0.

    SET F9_RUNTIME["launch_phase"] TO "LIFTOFF".
    SET F9_RUNTIME["running"] TO FALSE.
    SET F9_RUNTIME["held"] TO FALSE.
    SET F9_RUNTIME["mode"] TO "LIFTOFF READY".
    SET F9_RUNTIME["status_text"] TO "PAD RELEASED / LIFTOFF".
    SET F9_RUNTIME["next_tick_at"] TO -1.
    SET F9_RUNTIME["ui_dirty"] TO TRUE.
    OnClosePressed().
    SHUTDOWN.
}.

FUNCTION FindPresetIndex {
    PARAMETER targetLabel.

    LOCAL index TO 0.

    FOR presetLabel IN F9_COUNTDOWN_PRESETS {
        IF presetLabel = targetLabel {
            RETURN index.
        }.
        SET index TO index + 1.
    }.

    RETURN 0.
}.

FUNCTION ParseCountdownLabelToSeconds {
    PARAMETER countdownLabel.

    LOCAL parts TO countdownLabel:SPLIT(":").

    IF parts:LENGTH <> 3 {
        RETURN -1.
    }.

    RETURN parts[0]:TONUMBER * 3600 + parts[1]:TONUMBER * 60 + parts[2]:TONUMBER.
}.

FUNCTION LanDegreesToCountdownSeconds {
    PARAMETER lanDegrees.

    RETURN ROUND((lanDegrees / 360) * F9_KSP_DAY_SECONDS, 0).
}.

FUNCTION GetPresetIndexForCountdown {
    PARAMETER countdownSeconds.

    LOCAL targetSeconds TO ROUND(countdownSeconds, 0).
    LOCAL bestIndex TO 0.
    LOCAL bestDelta TO 999999.
    LOCAL index TO 0.

    FOR presetLabel IN F9_COUNTDOWN_PRESETS {
        LOCAL presetSeconds TO ParseCountdownLabelToSeconds(presetLabel).
        LOCAL delta TO presetSeconds - targetSeconds.
        IF delta < 0 {
            SET delta TO -delta.
        }.
        IF delta < bestDelta {
            SET bestDelta TO delta.
            SET bestIndex TO index.
        }.
        SET index TO index + 1.
    }.

    RETURN bestIndex.
}.

FUNCTION BuildFalcon9Gui {
    LOCAL titleText TO GetSettingOrDefault(F9_SETTINGS, "gui_title", F9_DEFAULT_TITLE).
    LOCAL subtitleText TO GetSettingOrDefault(F9_SETTINGS, "gui_subtitle", F9_DEFAULT_SUBTITLE).
    LOCAL missionText TO SHIP:NAME.

    IF missionText = "" {
        SET missionText TO F9_DEFAULT_MISSION_NAME.
    }.

    GLOBAL f9_gui IS GUI(F9_GUI_WIDTH, F9_GUI_HEIGHT).
    SET f9_gui:X TO F9_GUI_X.
    SET f9_gui:Y TO F9_GUI_Y.
    SET f9_gui:STYLE:ALIGN TO "center".
    SET f9_gui:STYLE:HSTRETCH TO TRUE.
    SET f9_gui:skin:LABEL:TEXTCOLOR TO RGB(0.86, 0.94, 0.90).

    GLOBAL f9_title_box IS f9_gui:ADDHBOX().
    SET f9_title_box:STYLE:HEIGHT TO 28.

    GLOBAL f9_title_label IS f9_title_box:ADDLABEL("<b><size=17>" + titleText + "</size></b>").
    SET f9_title_label:STYLE:ALIGN TO "center".
    SET f9_title_label:STYLE:TEXTCOLOR TO RGB(0.96, 0.84, 0.30).

    GLOBAL f9_mission_label IS f9_title_box:ADDLABEL("<size=13>" + missionText + "</size>").
    SET f9_mission_label:STYLE:ALIGN TO "right".
    SET f9_mission_label:STYLE:TEXTCOLOR TO RGB(0.80, 0.88, 0.92).

    f9_title_box:ADDSPACING(4).

    GLOBAL f9_minimize_button IS f9_title_box:ADDBUTTON("MIN").
    SET f9_minimize_button:STYLE:WIDTH TO 48.
    SET f9_minimize_button:STYLE:HEIGHT TO 22.
    SET f9_minimize_button:ONCLICK TO OnMinimizePressed@.

    GLOBAL f9_close_button IS f9_title_box:ADDBUTTON("X").
    SET f9_close_button:STYLE:WIDTH TO 30.
    SET f9_close_button:STYLE:HEIGHT TO 22.
    SET f9_close_button:ONCLICK TO OnClosePressed@.

    GLOBAL f9_subtitle_label IS f9_gui:ADDLABEL("<size=11>" + subtitleText + "</size>").
    SET f9_subtitle_label:STYLE:ALIGN TO "center".
    SET f9_subtitle_label:STYLE:TEXTCOLOR TO RGB(0.74, 0.80, 0.85).

    f9_gui:ADDSPACING(3).

    GLOBAL f9_status_box IS f9_gui:ADDVLAYOUT().
    SET f9_status_box:STYLE:WIDTH TO F9_GUI_WIDTH - 14.

    GLOBAL f9_mode_label IS f9_status_box:ADDLABEL("MODE: READY").
    SET f9_mode_label:STYLE:FONT TO "Consolas Bold".
    SET f9_mode_label:STYLE:FONTSIZE TO 15.
    SET f9_mode_label:STYLE:TEXTCOLOR TO RGB(0.82, 0.92, 0.86).

    GLOBAL f9_timer_label IS f9_status_box:ADDLABEL("T-00:06:00").
    SET f9_timer_label:STYLE:FONT TO "Consolas Bold".
    SET f9_timer_label:STYLE:FONTSIZE TO 22.
    SET f9_timer_label:STYLE:TEXTCOLOR TO RGB(0.92, 0.96, 0.88).

    GLOBAL f9_selected_label IS f9_status_box:ADDLABEL("COUNTDOWN: T-00:06:00").
    SET f9_selected_label:STYLE:FONT TO "Consolas Bold".
    SET f9_selected_label:STYLE:FONTSIZE TO 13.
    SET f9_selected_label:STYLE:TEXTCOLOR TO RGB(0.76, 0.86, 0.90).

    GLOBAL f9_status_label IS f9_status_box:ADDLABEL("STATUS: READY").
    SET f9_status_label:STYLE:FONT TO "Consolas Bold".
    SET f9_status_label:STYLE:FONTSIZE TO 13.
    SET f9_status_label:STYLE:TEXTCOLOR TO RGB(0.95, 0.84, 0.34).

    f9_gui:ADDSPACING(3).

    GLOBAL f9_file_label IS f9_gui:ADDLABEL("INPUTS: SHARED MISSION STATE / GUI DRIVEN").
    SET f9_file_label:STYLE:FONT TO "Consolas Bold".
    SET f9_file_label:STYLE:FONTSIZE TO 11.
    SET f9_file_label:STYLE:TEXTCOLOR TO RGB(0.68, 0.72, 0.76).

    f9_gui:ADDSPACING(3).

    GLOBAL f9_input_box IS f9_gui:ADDHLAYOUT().
    SET f9_input_box:STYLE:WIDTH TO F9_GUI_WIDTH - 14.

    GLOBAL f9_orbit_box IS f9_input_box:ADDVBOX().
    SET f9_orbit_box:STYLE:WIDTH TO 360.

    GLOBAL f9_orbit_title IS f9_orbit_box:ADDLABEL("TARGET ORBIT").
    SET f9_orbit_title:STYLE:FONT TO "Consolas Bold".
    SET f9_orbit_title:STYLE:FONTSIZE TO 13.
    SET f9_orbit_title:STYLE:TEXTCOLOR TO RGB(0.96, 0.84, 0.30).

    GLOBAL f9_apo_row IS f9_orbit_box:ADDHLAYOUT().
    GLOBAL f9_apo_label IS f9_apo_row:ADDLABEL("APOAPSIS").
    SET f9_apo_label:STYLE:WIDTH TO 80.
    SET f9_apo_label:STYLE:TEXTCOLOR TO RGB(0.80, 0.88, 0.92).
    GLOBAL f9_apo_slider IS f9_apo_row:ADDHSLIDER(F9_RUNTIME["target_apoapsis_km"], GetAtmosphericFloorKm(), 1000).
    SET f9_apo_slider:STYLE:WIDTH TO 98.
    SET f9_apo_slider:ONCHANGE TO OnApoapsisChanged@.
    GLOBAL f9_apo_textfield IS f9_apo_row:ADDTEXTFIELD("" + F9_RUNTIME["target_apoapsis_km"]).
    SET f9_apo_textfield:STYLE:WIDTH TO 50.
    SET f9_apo_textfield:TOOLTIP TO "km".
    SET f9_apo_textfield:ONCONFIRM TO OnApoapsisTextConfirmed@.
    GLOBAL f9_apo_value_label IS f9_apo_row:ADDLABEL(FormatKilometers(F9_RUNTIME["target_apoapsis_km"])).
    SET f9_apo_value_label:STYLE:WIDTH TO 52.

    GLOBAL f9_peri_row IS f9_orbit_box:ADDHLAYOUT().
    GLOBAL f9_peri_label IS f9_peri_row:ADDLABEL("PERIAPSIS").
    SET f9_peri_label:STYLE:WIDTH TO 80.
    SET f9_peri_label:STYLE:TEXTCOLOR TO RGB(0.80, 0.88, 0.92).
    GLOBAL f9_peri_slider IS f9_peri_row:ADDHSLIDER(F9_RUNTIME["target_periapsis_km"], GetAtmosphericFloorKm(), 1000).
    SET f9_peri_slider:STYLE:WIDTH TO 98.
    SET f9_peri_slider:ONCHANGE TO OnPeriapsisChanged@.
    GLOBAL f9_peri_textfield IS f9_peri_row:ADDTEXTFIELD("" + F9_RUNTIME["target_periapsis_km"]).
    SET f9_peri_textfield:STYLE:WIDTH TO 50.
    SET f9_peri_textfield:TOOLTIP TO "km".
    SET f9_peri_textfield:ONCONFIRM TO OnPeriapsisTextConfirmed@.
    GLOBAL f9_peri_value_label IS f9_peri_row:ADDLABEL(FormatKilometers(F9_RUNTIME["target_periapsis_km"])).
    SET f9_peri_value_label:STYLE:WIDTH TO 52.

    GLOBAL f9_inclination_row IS f9_orbit_box:ADDHLAYOUT().
    GLOBAL f9_inclination_label IS f9_inclination_row:ADDLABEL("INCLINATION").
    SET f9_inclination_label:STYLE:WIDTH TO 80.
    SET f9_inclination_label:STYLE:TEXTCOLOR TO RGB(0.80, 0.88, 0.92).
    GLOBAL f9_inclination_slider IS f9_inclination_row:ADDHSLIDER(F9_RUNTIME["target_inclination_deg"], -120, 120).
    SET f9_inclination_slider:STYLE:WIDTH TO 98.
    SET f9_inclination_slider:ONCHANGE TO OnInclinationChanged@.
    GLOBAL f9_inclination_textfield IS f9_inclination_row:ADDTEXTFIELD("" + F9_RUNTIME["target_inclination_deg"]).
    SET f9_inclination_textfield:STYLE:WIDTH TO 50.
    SET f9_inclination_textfield:TOOLTIP TO "deg".
    SET f9_inclination_textfield:ONCONFIRM TO OnInclinationTextConfirmed@.
    GLOBAL f9_inclination_value_label IS f9_inclination_row:ADDLABEL(FormatDegrees(F9_RUNTIME["target_inclination_deg"])).
    SET f9_inclination_value_label:STYLE:WIDTH TO 52.

    GLOBAL f9_lan_row IS f9_orbit_box:ADDHLAYOUT().
    GLOBAL f9_lan_label IS f9_lan_row:ADDLABEL("LAN").
    SET f9_lan_label:STYLE:WIDTH TO 80.
    SET f9_lan_label:STYLE:TEXTCOLOR TO RGB(0.80, 0.88, 0.92).
    GLOBAL f9_lan_slider IS f9_lan_row:ADDHSLIDER(F9_RUNTIME["target_lan_deg"], 0, 360).
    SET f9_lan_slider:STYLE:WIDTH TO 98.
    SET f9_lan_slider:ONCHANGE TO OnLanChanged@.
    GLOBAL f9_lan_textfield IS f9_lan_row:ADDTEXTFIELD("" + F9_RUNTIME["target_lan_deg"]).
    SET f9_lan_textfield:STYLE:WIDTH TO 50.
    SET f9_lan_textfield:TOOLTIP TO "deg".
    SET f9_lan_textfield:ONCONFIRM TO OnLanTextConfirmed@.
    GLOBAL f9_lan_value_label IS f9_lan_row:ADDLABEL(FormatDegrees(F9_RUNTIME["target_lan_deg"])).
    SET f9_lan_value_label:STYLE:WIDTH TO 52.

    GLOBAL f9_countdown_box IS f9_input_box:ADDVBOX().
    SET f9_countdown_box:STYLE:WIDTH TO 220.

    GLOBAL f9_countdown_title IS f9_countdown_box:ADDLABEL("COUNTDOWN").
    SET f9_countdown_title:STYLE:FONT TO "Consolas Bold".
    SET f9_countdown_title:STYLE:FONTSIZE TO 13.
    SET f9_countdown_title:STYLE:TEXTCOLOR TO RGB(0.96, 0.84, 0.30).

    GLOBAL f9_countdown_row IS f9_countdown_box:ADDHLAYOUT().
    GLOBAL f9_countdown_label IS f9_countdown_row:ADDLABEL("T-MINUS").
    SET f9_countdown_label:STYLE:WIDTH TO 52.
    SET f9_countdown_label:STYLE:TEXTCOLOR TO RGB(0.80, 0.88, 0.92).
    GLOBAL f9_countdown_menu IS f9_countdown_row:ADDPOPUPMENU().
    SET f9_countdown_menu:STYLE:WIDTH TO 84.
    SET f9_countdown_menu:STYLE:HEIGHT TO 24.
    SET f9_countdown_menu:OPTIONS TO F9_COUNTDOWN_PRESETS.
    SET f9_countdown_menu:INDEX TO FindPresetIndex(FormatSecondsAsClock(F9_RUNTIME["selected_countdown_seconds"])).
    SET f9_countdown_menu:ONCHANGE TO OnCountdownChanged@.
    GLOBAL f9_countdown_value_label IS f9_countdown_row:ADDLABEL(FormatSecondsAsClock(F9_RUNTIME["selected_countdown_seconds"])).
    SET f9_countdown_value_label:STYLE:WIDTH TO 72.

    GLOBAL f9_recovery_box IS f9_countdown_box:ADDVBOX().
    SET f9_recovery_box:STYLE:WIDTH TO 220.

    GLOBAL f9_recovery_title IS f9_recovery_box:ADDLABEL("STAGE 1 RECOVERY").
    SET f9_recovery_title:STYLE:FONT TO "Consolas Bold".
    SET f9_recovery_title:STYLE:FONTSIZE TO 13.
    SET f9_recovery_title:STYLE:TEXTCOLOR TO RGB(0.96, 0.84, 0.30).

    GLOBAL f9_recovery_row IS f9_recovery_box:ADDHLAYOUT().
    GLOBAL f9_recovery_label IS f9_recovery_row:ADDLABEL("METHOD").
    SET f9_recovery_label:STYLE:WIDTH TO 52.
    SET f9_recovery_label:STYLE:TEXTCOLOR TO RGB(0.80, 0.88, 0.92).
    GLOBAL f9_recovery_menu IS f9_recovery_row:ADDPOPUPMENU().
    SET f9_recovery_menu:STYLE:WIDTH TO 78.
    SET f9_recovery_menu:STYLE:HEIGHT TO 24.
    SET f9_recovery_menu:OPTIONS TO LIST("RTLS", "ASDS").
    SET f9_recovery_menu:INDEX TO FindRecoveryIndex(F9_RUNTIME["recovery_method"]).
    SET f9_recovery_menu:ONCHANGE TO OnRecoveryChanged@.
    GLOBAL f9_recovery_value_label IS f9_recovery_row:ADDLABEL(F9_RUNTIME["recovery_method"] + " / MECO " + ROUND(F9_RUNTIME["meco_fuel_percent"], 1) + "%").
    SET f9_recovery_value_label:STYLE:WIDTH TO 102.

    f9_gui:ADDSPACING(4).

    GLOBAL f9_button_box IS f9_gui:ADDHLAYOUT().
    SET f9_button_box:STYLE:WIDTH TO F9_GUI_WIDTH - 14.

    GLOBAL f9_start_button IS f9_button_box:ADDBUTTON("START").
    SET f9_start_button:STYLE:WIDTH TO 108.
    SET f9_start_button:STYLE:HEIGHT TO 26.
    SET f9_start_button:ONCLICK TO OnStartPressed@.

    GLOBAL f9_hold_button IS f9_button_box:ADDBUTTON("HOLD").
    SET f9_hold_button:STYLE:WIDTH TO 108.
    SET f9_hold_button:STYLE:HEIGHT TO 26.
    SET f9_hold_button:TOGGLE TO TRUE.
    SET f9_hold_button:ONTOGGLE TO OnHoldToggled@.

    GLOBAL f9_recycle_button IS f9_button_box:ADDBUTTON("RECYCLE").
    SET f9_recycle_button:STYLE:WIDTH TO 108.
    SET f9_recycle_button:STYLE:HEIGHT TO 26.
    SET f9_recycle_button:ONCLICK TO OnRecyclePressed@.

    GLOBAL f9_debug_button IS f9_button_box:ADDBUTTON("DEBUG").
    SET f9_debug_button:STYLE:WIDTH TO 72.
    SET f9_debug_button:STYLE:HEIGHT TO 26.
    SET f9_debug_button:TOOLTIP TO "Open the in-game kOS terminal.".
    SET f9_debug_button:ONCLICK TO OnDebugPressed@.

    f9_gui:SHOW().
    SyncOrbitControlsToFloor().
    SetFalcon9WindowState(FALSE).
}.

FUNCTION OnApoapsisChanged {
    PARAMETER value.

    SET F9_RUNTIME["target_apoapsis_km"] TO ClampOrbitAltitudeKm(ROUND(value, 0)).
    SET f9_apo_textfield:TEXT TO "" + F9_RUNTIME["target_apoapsis_km"].
    SET f9_apo_value_label:TEXT TO FormatKilometers(F9_RUNTIME["target_apoapsis_km"]).
    SET F9_RUNTIME["status_text"] TO "APOAPSIS UPDATED".
    SET F9_RUNTIME["ui_dirty"] TO TRUE.
    SaveFalcon9MissionState().
}.

FUNCTION OnApoapsisTextConfirmed {
    PARAMETER textValue.

    LOCAL parsedApo TO textValue:TONUMBER(-1).

    IF parsedApo < 0 {
        SET f9_apo_textfield:TEXT TO "" + F9_RUNTIME["target_apoapsis_km"].
        RETURN.
    }.

    SET parsedApo TO ROUND(parsedApo, 0).
    SET parsedApo TO ClampOrbitAltitudeKm(parsedApo).
    SET F9_RUNTIME["target_apoapsis_km"] TO parsedApo.
    SET f9_apo_slider:VALUE TO parsedApo.
    SET f9_apo_textfield:TEXT TO "" + parsedApo.
    SET f9_apo_value_label:TEXT TO FormatKilometers(parsedApo).
    SET F9_RUNTIME["status_text"] TO "APOAPSIS UPDATED".
    SET F9_RUNTIME["ui_dirty"] TO TRUE.
    SaveFalcon9MissionState().
}.

FUNCTION OnPeriapsisChanged {
    PARAMETER value.

    SET F9_RUNTIME["target_periapsis_km"] TO ClampOrbitAltitudeKm(ROUND(value, 0)).
    SET f9_peri_textfield:TEXT TO "" + F9_RUNTIME["target_periapsis_km"].
    SET f9_peri_value_label:TEXT TO FormatKilometers(F9_RUNTIME["target_periapsis_km"]).
    SET F9_RUNTIME["status_text"] TO "PERIAPSIS UPDATED".
    SET F9_RUNTIME["ui_dirty"] TO TRUE.
    SaveFalcon9MissionState().
}.

FUNCTION OnPeriapsisTextConfirmed {
    PARAMETER textValue.

    LOCAL parsedPeri TO textValue:TONUMBER(-1).

    IF parsedPeri < 0 {
        SET f9_peri_textfield:TEXT TO "" + F9_RUNTIME["target_periapsis_km"].
        RETURN.
    }.

    SET parsedPeri TO ROUND(parsedPeri, 0).
    SET parsedPeri TO ClampOrbitAltitudeKm(parsedPeri).
    SET F9_RUNTIME["target_periapsis_km"] TO parsedPeri.
    SET f9_peri_slider:VALUE TO parsedPeri.
    SET f9_peri_textfield:TEXT TO "" + parsedPeri.
    SET f9_peri_value_label:TEXT TO FormatKilometers(parsedPeri).
    SET F9_RUNTIME["status_text"] TO "PERIAPSIS UPDATED".
    SET F9_RUNTIME["ui_dirty"] TO TRUE.
    SaveFalcon9MissionState().
}.

FUNCTION OnInclinationChanged {
    PARAMETER value.

    SET F9_RUNTIME["target_inclination_deg"] TO ROUND(value * 10, 0) / 10.
    SET f9_inclination_textfield:TEXT TO "" + F9_RUNTIME["target_inclination_deg"].
    SET f9_inclination_value_label:TEXT TO FormatDegrees(F9_RUNTIME["target_inclination_deg"]).
    SET F9_RUNTIME["status_text"] TO "INCLINATION UPDATED".
    SET F9_RUNTIME["ui_dirty"] TO TRUE.
    SaveFalcon9MissionState().
}.

FUNCTION OnInclinationTextConfirmed {
    PARAMETER textValue.

    LOCAL parsedInclination TO textValue:TONUMBER(999999).

    IF parsedInclination = 999999 {
        SET f9_inclination_textfield:TEXT TO "" + F9_RUNTIME["target_inclination_deg"].
        RETURN.
    }.

    SET parsedInclination TO ROUND(parsedInclination * 10, 0) / 10.
    SET parsedInclination TO ClampNumber(parsedInclination, -120, 120).
    SET F9_RUNTIME["target_inclination_deg"] TO parsedInclination.
    SET f9_inclination_slider:VALUE TO parsedInclination.
    SET f9_inclination_textfield:TEXT TO "" + parsedInclination.
    SET f9_inclination_value_label:TEXT TO FormatDegrees(parsedInclination).
    SET F9_RUNTIME["status_text"] TO "INCLINATION UPDATED".
    SET F9_RUNTIME["ui_dirty"] TO TRUE.
    SaveFalcon9MissionState().
}.

FUNCTION OnLanChanged {
    PARAMETER value.

    SET F9_RUNTIME["target_lan_deg"] TO ROUND(value * 10, 0) / 10.
    SET f9_lan_textfield:TEXT TO "" + F9_RUNTIME["target_lan_deg"].
    SET f9_lan_value_label:TEXT TO FormatDegrees(F9_RUNTIME["target_lan_deg"]).

    SET F9_RUNTIME["selected_countdown_seconds"] TO LanDegreesToCountdownSeconds(F9_RUNTIME["target_lan_deg"]).

    IF NOT F9_RUNTIME["running"] {
        SET F9_RUNTIME["countdown_seconds"] TO F9_RUNTIME["selected_countdown_seconds"].
    }.

    SET f9_countdown_menu:INDEX TO GetPresetIndexForCountdown(F9_RUNTIME["selected_countdown_seconds"]).
    SET f9_countdown_value_label:TEXT TO FormatSecondsAsClock(F9_RUNTIME["selected_countdown_seconds"]).
    SET F9_RUNTIME["status_text"] TO "LAN UPDATED / COUNTDOWN SYNCED".
    SET F9_RUNTIME["ui_dirty"] TO TRUE.
    SaveFalcon9MissionState().
}.

FUNCTION OnLanTextConfirmed {
    PARAMETER textValue.

    LOCAL parsedLan TO textValue:TONUMBER(999999).

    IF parsedLan = 999999 {
        SET f9_lan_textfield:TEXT TO "" + F9_RUNTIME["target_lan_deg"].
        RETURN.
    }.

    SET parsedLan TO ROUND(parsedLan * 10, 0) / 10.
    SET parsedLan TO ClampNumber(parsedLan, 0, 360).
    SET F9_RUNTIME["target_lan_deg"] TO parsedLan.
    SET f9_lan_slider:VALUE TO parsedLan.
    SET f9_lan_textfield:TEXT TO "" + parsedLan.
    SET f9_lan_value_label:TEXT TO FormatDegrees(parsedLan).

    SET F9_RUNTIME["selected_countdown_seconds"] TO LanDegreesToCountdownSeconds(F9_RUNTIME["target_lan_deg"]).

    IF NOT F9_RUNTIME["running"] {
        SET F9_RUNTIME["countdown_seconds"] TO F9_RUNTIME["selected_countdown_seconds"].
    }.

    SET f9_countdown_menu:INDEX TO GetPresetIndexForCountdown(F9_RUNTIME["selected_countdown_seconds"]).
    SET f9_countdown_value_label:TEXT TO FormatSecondsAsClock(F9_RUNTIME["selected_countdown_seconds"]).
    SET F9_RUNTIME["status_text"] TO "LAN UPDATED / COUNTDOWN SYNCED".
    SET F9_RUNTIME["ui_dirty"] TO TRUE.
    SaveFalcon9MissionState().
}.

FUNCTION FindRecoveryIndex {
    PARAMETER methodName.

    IF methodName = "ASDS" {
        RETURN 1.
    }.

    RETURN 0.
}.

FUNCTION GetRecoveryMecoFuelPercent {
    PARAMETER methodName.

    IF methodName = "ASDS" {
        RETURN 18.5.
    }.

    RETURN 25.5.
}.

FUNCTION OnRecoveryChanged {
    PARAMETER methodName.

    LOCAL normalizedMethod TO methodName.

    IF normalizedMethod <> "ASDS" {
        SET normalizedMethod TO "RTLS".
    }.

    SET F9_RUNTIME["recovery_method"] TO normalizedMethod.
    SET F9_RUNTIME["meco_fuel_percent"] TO GetRecoveryMecoFuelPercent(normalizedMethod).
    SET f9_recovery_value_label:TEXT TO normalizedMethod + " / MECO " + ROUND(F9_RUNTIME["meco_fuel_percent"], 1) + "%".
    SET F9_RUNTIME["status_text"] TO "RECOVERY METHOD UPDATED".
    SET F9_RUNTIME["ui_dirty"] TO TRUE.
    SaveFalcon9MissionState().
}.

FUNCTION OnCountdownChanged {
    PARAMETER presetLabel.

    LOCAL selectedSeconds TO ParseCountdownLabelToSeconds(presetLabel).

    IF selectedSeconds < 0 {
        RETURN.
    }.

    SET F9_RUNTIME["selected_countdown_seconds"] TO selectedSeconds.

    IF NOT F9_RUNTIME["running"] {
        SET F9_RUNTIME["countdown_seconds"] TO selectedSeconds.
    }.

    SET f9_countdown_value_label:TEXT TO FormatSecondsAsClock(F9_RUNTIME["selected_countdown_seconds"]).
    SET F9_RUNTIME["status_text"] TO "COUNTDOWN UPDATED".
    SET F9_RUNTIME["ui_dirty"] TO TRUE.
    SaveFalcon9MissionState().
}.

FUNCTION OnStartPressed {
    IF F9_RUNTIME["running"] OR F9_RUNTIME["launch_phase"] = "LIFTOFF" {
        RETURN.
    }.

    RCS OFF.
    ResetFalcon9LaunchState().
    SET F9_RUNTIME["launch_phase"] TO "COUNTDOWN".
    SET F9_RUNTIME["launch_abort_reason"] TO "".
    SET F9_RUNTIME["countdown_seconds"] TO F9_RUNTIME["selected_countdown_seconds"].
    SET F9_RUNTIME["running"] TO TRUE.
    SET F9_RUNTIME["held"] TO FALSE.
    SET F9_RUNTIME["mode"] TO "RUNNING".
    SET F9_RUNTIME["status_text"] TO "COUNTDOWN RUNNING".
    SET F9_RUNTIME["next_tick_at"] TO TIME:SECONDS + 1.
    SET F9_RUNTIME["ui_dirty"] TO TRUE.

    SET f9_hold_button:PRESSED TO FALSE.
    SET f9_hold_button:TEXT TO "HOLD".
    SaveFalcon9MissionState().
}.

FUNCTION OnHoldToggled {
    PARAMETER pressed.

    IF NOT F9_RUNTIME["running"] {
        SET f9_hold_button:PRESSED TO FALSE.
        RETURN.
    }.

    IF pressed {
        SET F9_RUNTIME["held"] TO TRUE.
        SET F9_RUNTIME["mode"] TO "HOLD".
        SET F9_RUNTIME["status_text"] TO "COUNTDOWN HOLD".
        SET F9_RUNTIME["next_tick_at"] TO -1.
        SET f9_hold_button:TEXT TO "RESUME".
    } ELSE {
        SET F9_RUNTIME["held"] TO FALSE.
        SET F9_RUNTIME["mode"] TO "RUNNING".
        SET F9_RUNTIME["status_text"] TO "COUNTDOWN RUNNING".
        SET F9_RUNTIME["next_tick_at"] TO TIME:SECONDS + 1.
        SET f9_hold_button:TEXT TO "HOLD".
    }.

    SET F9_RUNTIME["ui_dirty"] TO TRUE.
}.

FUNCTION OnRecyclePressed {
    LOCK THROTTLE TO 0.
    UNLOCK STEERING.
    SET F9_RUNTIME["running"] TO FALSE.
    SET F9_RUNTIME["held"] TO FALSE.
    SET F9_RUNTIME["mode"] TO "SETUP".
    SET F9_RUNTIME["countdown_seconds"] TO F9_RUNTIME["selected_countdown_seconds"].
    SET F9_RUNTIME["next_tick_at"] TO -1.
    SET F9_RUNTIME["status_text"] TO "RECYCLED TO SETUP".
    SET F9_RUNTIME["launch_phase"] TO "IDLE".
    SET F9_RUNTIME["launch_abort_reason"] TO "".
    SET F9_RUNTIME["ui_dirty"] TO TRUE.

    SET f9_hold_button:PRESSED TO FALSE.
    SET f9_hold_button:TEXT TO "HOLD".
}.

FUNCTION OnDebugPressed {
    CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
    SET F9_RUNTIME["status_text"] TO "KOS TERMINAL OPENED".
    SET F9_RUNTIME["ui_dirty"] TO TRUE.
}.

FUNCTION OnMinimizePressed {
    IF F9_RUNTIME["ui_closed"] {
        RETURN.
    }.

    IF F9_RUNTIME["minimized"] {
        SetFalcon9WindowState(FALSE).
    } ELSE {
        SetFalcon9WindowState(TRUE).
    }.
}.

FUNCTION OnClosePressed {
    SET F9_RUNTIME["ui_closed"] TO TRUE.
    CLEARGUIS().
}.

FUNCTION ShouldGrayOutAbortControls {
    RETURN F9_RUNTIME["launch_phase"] <> "ABORTED" AND F9_RUNTIME["countdown_seconds"] <= 10.
}.

FUNCTION SyncFalcon9Gui {
    PARAMETER forceRefresh.

    IF F9_RUNTIME["ui_closed"] {
        RETURN.
    }.

    LOCAL modeText TO F9_RUNTIME["mode"].
    LOCAL currentClock TO FormatSecondsAsClock(F9_RUNTIME["countdown_seconds"]).
    LOCAL selectedClock TO FormatSecondsAsClock(F9_RUNTIME["selected_countdown_seconds"]).
    LOCAL timerPrefix TO "T-".

    IF modeText = "LIFTOFF READY" {
        SET timerPrefix TO "T+".
    }.

    SET f9_mode_label:TEXT TO "MODE: " + modeText.
    SET f9_timer_label:TEXT TO timerPrefix + currentClock.
    SET f9_selected_label:TEXT TO "COUNTDOWN: T-" + selectedClock.
    SET f9_status_label:TEXT TO "STATUS: " + F9_RUNTIME["status_text"].
    SET f9_file_label:TEXT TO "INPUTS: SHARED MISSION STATE / GUI DRIVEN".

    SET f9_apo_value_label:TEXT TO FormatKilometers(F9_RUNTIME["target_apoapsis_km"]).
    SET f9_peri_value_label:TEXT TO FormatKilometers(F9_RUNTIME["target_periapsis_km"]).
    SET f9_inclination_value_label:TEXT TO FormatDegrees(F9_RUNTIME["target_inclination_deg"]).
    SET f9_lan_value_label:TEXT TO FormatDegrees(F9_RUNTIME["target_lan_deg"]).
    SET f9_recovery_value_label:TEXT TO F9_RUNTIME["recovery_method"] + " / MECO " + ROUND(F9_RUNTIME["meco_fuel_percent"], 1) + "%".
    SET f9_countdown_value_label:TEXT TO FormatSecondsAsClock(F9_RUNTIME["selected_countdown_seconds"]).

    SET f9_apo_slider:VALUE TO F9_RUNTIME["target_apoapsis_km"].
    SET f9_peri_slider:VALUE TO F9_RUNTIME["target_periapsis_km"].
    SET f9_inclination_slider:VALUE TO F9_RUNTIME["target_inclination_deg"].
    SET f9_lan_slider:VALUE TO F9_RUNTIME["target_lan_deg"].
    SET f9_recovery_menu:INDEX TO FindRecoveryIndex(F9_RUNTIME["recovery_method"]).
    SET f9_countdown_menu:INDEX TO GetPresetIndexForCountdown(F9_RUNTIME["selected_countdown_seconds"]).

    IF F9_RUNTIME["held"] {
        SET f9_hold_button:TEXT TO "RESUME".
    } ELSE {
        SET f9_hold_button:TEXT TO "HOLD".
    }.

    f9_hold_button:SHOW().
    f9_recycle_button:SHOW().

    IF F9_RUNTIME["running"] {
        SET f9_start_button:ENABLED TO FALSE.
        SET f9_hold_button:ENABLED TO NOT ShouldGrayOutAbortControls().
        SET f9_apo_slider:ENABLED TO FALSE.
        SET f9_peri_slider:ENABLED TO FALSE.
        SET f9_inclination_slider:ENABLED TO FALSE.
        SET f9_lan_slider:ENABLED TO FALSE.
        SET f9_recovery_menu:ENABLED TO FALSE.
        SET f9_countdown_menu:ENABLED TO FALSE.
        SET f9_recycle_button:ENABLED TO NOT ShouldGrayOutAbortControls().
        SET f9_debug_button:ENABLED TO TRUE.
    } ELSE IF F9_RUNTIME["launch_phase"] = "LIFTOFF" {
        SET f9_start_button:ENABLED TO FALSE.
        SET f9_hold_button:ENABLED TO FALSE.
        SET f9_apo_slider:ENABLED TO FALSE.
        SET f9_peri_slider:ENABLED TO FALSE.
        SET f9_inclination_slider:ENABLED TO FALSE.
        SET f9_lan_slider:ENABLED TO FALSE.
        SET f9_recovery_menu:ENABLED TO FALSE.
        SET f9_countdown_menu:ENABLED TO FALSE.
        SET f9_recycle_button:ENABLED TO TRUE.
        SET f9_debug_button:ENABLED TO TRUE.
    } ELSE IF F9_RUNTIME["launch_phase"] = "ABORTED" {
        SET f9_start_button:ENABLED TO TRUE.
        SET f9_hold_button:ENABLED TO TRUE.
        SET f9_apo_slider:ENABLED TO TRUE.
        SET f9_peri_slider:ENABLED TO TRUE.
        SET f9_inclination_slider:ENABLED TO TRUE.
        SET f9_lan_slider:ENABLED TO TRUE.
        SET f9_recovery_menu:ENABLED TO TRUE.
        SET f9_countdown_menu:ENABLED TO TRUE.
        SET f9_recycle_button:ENABLED TO TRUE.
        SET f9_debug_button:ENABLED TO TRUE.
    } ELSE {
        SET f9_start_button:ENABLED TO TRUE.
        SET f9_hold_button:ENABLED TO TRUE.
        SET f9_apo_slider:ENABLED TO TRUE.
        SET f9_peri_slider:ENABLED TO TRUE.
        SET f9_inclination_slider:ENABLED TO TRUE.
        SET f9_lan_slider:ENABLED TO TRUE.
        SET f9_recovery_menu:ENABLED TO TRUE.
        SET f9_countdown_menu:ENABLED TO TRUE.
        SET f9_recycle_button:ENABLED TO TRUE.
        SET f9_debug_button:ENABLED TO TRUE.
    }.

    IF forceRefresh OR F9_RUNTIME["ui_dirty"] {
        SaveFalcon9MissionState().
        SET F9_RUNTIME["ui_dirty"] TO FALSE.
    }.
}.

FUNCTION RunFalcon9Console {
    UNTIL FALSE {
        IF F9_RUNTIME["ui_closed"] {
            WAIT 0.2.
            CONTINUE.
        }.

        IF F9_RUNTIME["running"] AND NOT F9_RUNTIME["held"] {
            LOCAL launchTickDue TO TIME:SECONDS >= F9_RUNTIME["next_tick_at"].

            IF F9_RUNTIME["launch_phase"] = "COUNTDOWN" {
                LOCAL gateReason TO CheckFalcon9LaunchGates().
                IF gateReason <> "" {
                    AbortFalcon9Launch(gateReason).
                }.
            }.

            IF launchTickDue AND F9_RUNTIME["running"] AND NOT F9_RUNTIME["held"] {
                IF F9_RUNTIME["launch_phase"] = "COUNTDOWN" AND F9_RUNTIME["countdown_seconds"] <= F9_IGNITION_T_MINUS {
                    IgniteFalcon9FirstStage().
                }.

                IF F9_RUNTIME["countdown_seconds"] > 0 {
                    SET F9_RUNTIME["countdown_seconds"] TO F9_RUNTIME["countdown_seconds"] - 1.
                    SET F9_RUNTIME["next_tick_at"] TO TIME:SECONDS + 1.
                    SET F9_RUNTIME["ui_dirty"] TO TRUE.
                } ELSE {
                    SET F9_RUNTIME["next_tick_at"] TO -1.
                }.

                IF F9_RUNTIME["launch_phase"] = "IGNITED" AND F9_RUNTIME["countdown_seconds"] <= 0 {
                    ReleaseFalcon9FromPad().
                } ELSE IF F9_RUNTIME["launch_phase"] = "COUNTDOWN" AND F9_RUNTIME["countdown_seconds"] <= 0 {
                    SET F9_RUNTIME["status_text"] TO "T-0 REACHED - LAUNCH HANDOFF PENDING".
                    SET F9_RUNTIME["mode"] TO "LIFTOFF READY".
                    SET F9_RUNTIME["running"] TO FALSE.
                    SET F9_RUNTIME["next_tick_at"] TO -1.
                    SET F9_RUNTIME["ui_dirty"] TO TRUE.
                }.
            }.
        }.

        SyncFalcon9Gui(FALSE).
        WAIT 0.1.
    }.
}.
