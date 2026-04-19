@LAZYGLOBAL OFF.

GLOBAL F9_STAGE1_GUI_WIDTH IS 560.
GLOBAL F9_STAGE1_GUI_HEIGHT IS 300.
GLOBAL F9_STAGE1_GUI_MIN_HEIGHT IS 68.
GLOBAL F9_STAGE1_GUI_GRAPH_EXTRA_HEIGHT IS 220.
GLOBAL F9_STAGE1_GUI_X IS 222.
GLOBAL F9_STAGE1_GUI_Y IS 84.
GLOBAL F9_STAGE1_MISSION_STATE_PATH IS "0:/Falcon9/MISSION_STATE.json".
RUNPATH("0:/Falcon9/F9_LAZcalc.ks").
RUNPATH("0:/Falcon9/F9_TRAJECTORY.ks").
GLOBAL F9_STAGE1_TRAJECTORY_STATE_PATH IS "0:/Falcon9/MISSION_STATE.json".

GLOBAL F9_STAGE1_DEFAULT_TITLE IS "FALCON 9 STAGE 1 ASCENT".
GLOBAL F9_STAGE1_DEFAULT_SUBTITLE IS "STAGE 1 GUIDANCE / PROFILE HANDOFF".

GLOBAL F9_STAGE1_RUNTIME IS LEXICON(
    "mode", "ARMED",
    "guidance_enabled", TRUE,
    "held", FALSE,
    "ui_closed", FALSE,
    "ui_visible", FALSE,
    "minimized", FALSE,
    "live", FALSE,
    "status_text", "GUIDANCE ARMED / WAITING FOR LIFTOFF",
    "pitch_target", 90,
    "smoothed_pitch_deg", 90,
    "throttle_target", 0,
    "target_apoapsis_km", 80,
    "target_periapsis_km", 80,
    "target_inclination_deg", 0,
    "target_lan_deg", 0,
    "recovery_method", "RTLS",
    "meco_fuel_percent", 25.5,
    "stage_fuel_start_units", 0,
    "meco_reached", FALSE,
    "throttle_armed", FALSE,
    "qbucket_active", FALSE,
    "max_q_peak", 0,
    "stabilizing", FALSE,
    "handoff_phase", "IDLE",
    "trajectory_graph_visible", FALSE,
    "trajectory_state", 0,
    "ui_dirty", TRUE
).

GLOBAL f9_stage1_gui IS 0.
GLOBAL f9_stage1_title_label IS 0.
GLOBAL f9_stage1_subtitle_label IS 0.
GLOBAL f9_stage1_mode_label IS 0.
GLOBAL f9_stage1_altitude_label IS 0.
GLOBAL f9_stage1_speed_label IS 0.
GLOBAL f9_stage1_pitch_label IS 0.
GLOBAL f9_stage1_throttle_label IS 0.
GLOBAL f9_stage1_recovery_label IS 0.
GLOBAL f9_stage1_status_label IS 0.
GLOBAL f9_stage1_guidance_button IS 0.
GLOBAL f9_stage1_trajectory_button IS 0.
GLOBAL f9_stage1_graph_box IS 0.
GLOBAL f9_stage1_graph_title_label IS 0.
GLOBAL f9_stage1_graph_label IS 0.
GLOBAL f9_stage1_minimize_button IS 0.
GLOBAL f9_stage1_close_button IS 0.

CLEARGUIS().
LoadStage1MissionState().
LoadStage1TrajectoryState().
BuildStage1Gui().
SyncStage1Gui(TRUE).
RunStage1Console().

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

FUNCTION GetStage1StateOrDefault {
    PARAMETER record, key, defaultValue.

    IF record:HASKEY(key) {
        RETURN record[key].
    }.

    RETURN defaultValue.
}.

FUNCTION GetStage1RecoveryMecoFuelPercent {
    PARAMETER methodName.

    IF methodName = "ASDS" {
        RETURN 18.5.
    }.

    RETURN 25.5.
}.

FUNCTION GetStage1FuelUnits {
    RETURN STAGE:LIQUIDFUEL + STAGE:OXIDIZER.
}.

FUNCTION GetStage1FuelPercentRemaining {
    LOCAL startUnits TO F9_STAGE1_RUNTIME["stage_fuel_start_units"].
    LOCAL currentUnits TO GetStage1FuelUnits().

    IF startUnits <= 0 {
        RETURN 100.
    }.

    RETURN ClampNumber((currentUnits / startUnits) * 100, 0, 100).
}.

FUNCTION SaveStage1MissionState {
    LOCAL missionState TO GetStage1MissionState().
    SET missionState["target_apoapsis_km"] TO F9_STAGE1_RUNTIME["target_apoapsis_km"].
    SET missionState["target_periapsis_km"] TO F9_STAGE1_RUNTIME["target_periapsis_km"].
    SET missionState["target_inclination_deg"] TO F9_STAGE1_RUNTIME["target_inclination_deg"].
    SET missionState["target_lan_deg"] TO F9_STAGE1_RUNTIME["target_lan_deg"].
    SET missionState["recovery_method"] TO F9_STAGE1_RUNTIME["recovery_method"].
    SET missionState["meco_fuel_percent"] TO F9_STAGE1_RUNTIME["meco_fuel_percent"].
    SET missionState["stage_fuel_start_units"] TO F9_STAGE1_RUNTIME["stage_fuel_start_units"].
    SET missionState["stabilizing"] TO F9_STAGE1_RUNTIME["stabilizing"].
    SET missionState["handoff_phase"] TO F9_STAGE1_RUNTIME["handoff_phase"].

    WRITEJSON(missionState, F9_STAGE1_MISSION_STATE_PATH).
}.

FUNCTION GetStage1TrajectoryState {
    IF EXISTS(F9_STAGE1_TRAJECTORY_STATE_PATH) {
        LOCAL trajectoryState TO READJSON(F9_STAGE1_TRAJECTORY_STATE_PATH).

        IF NOT trajectoryState:HASKEY("trajectory_samples") {
            SET trajectoryState["trajectory_samples"] TO LIST().
        }.

        IF NOT trajectoryState:HASKEY("trajectory_origin_lat") {
            SET trajectoryState["trajectory_origin_lat"] TO SHIP:LATITUDE.
        }.

        IF NOT trajectoryState:HASKEY("trajectory_origin_lng") {
            SET trajectoryState["trajectory_origin_lng"] TO SHIP:LONGITUDE.
        }.

        IF NOT trajectoryState:HASKEY("last_sample_time") {
            SET trajectoryState["last_sample_time"] TO -9999.
        }.

        RETURN trajectoryState.
    }.

    RETURN LEXICON(
        "trajectory_samples", LIST(),
        "trajectory_origin_lat", SHIP:LATITUDE,
        "trajectory_origin_lng", SHIP:LONGITUDE,
        "last_sample_time", -9999
    ).
}.

FUNCTION LoadStage1TrajectoryState {
    SET F9_STAGE1_RUNTIME["trajectory_state"] TO GetStage1TrajectoryState().
}.

FUNCTION SaveStage1TrajectoryState {
    LOCAL trajectoryState TO GetStage1TrajectoryState().
    SET trajectoryState["trajectory_samples"] TO F9_STAGE1_RUNTIME["trajectory_state"]["trajectory_samples"].
    SET trajectoryState["trajectory_origin_lat"] TO F9_STAGE1_RUNTIME["trajectory_state"]["trajectory_origin_lat"].
    SET trajectoryState["trajectory_origin_lng"] TO F9_STAGE1_RUNTIME["trajectory_state"]["trajectory_origin_lng"].
    SET trajectoryState["last_sample_time"] TO F9_STAGE1_RUNTIME["trajectory_state"]["last_sample_time"].
    WRITEJSON(trajectoryState, F9_STAGE1_TRAJECTORY_STATE_PATH).
}.

FUNCTION UpdateStage1TrajectoryGraph {
    IF NOT F9_STAGE1_RUNTIME["trajectory_graph_visible"] {
        RETURN.
    }.

    SET f9_stage1_graph_label:TEXT TO F9TrajectoryRender(F9_STAGE1_RUNTIME["trajectory_state"], "S1", 46, 14, "STAGE 1 TRAJECTORY").
    SET F9_STAGE1_RUNTIME["ui_dirty"] TO TRUE.
}.

FUNCTION SetStage1TrajectoryGraphVisible {
    PARAMETER visible.

    SET F9_STAGE1_RUNTIME["trajectory_graph_visible"] TO visible.

    IF visible {
        f9_stage1_graph_box:SHOW().
        SET f9_stage1_gui:STYLE:HEIGHT TO F9_STAGE1_GUI_HEIGHT + F9_STAGE1_GUI_GRAPH_EXTRA_HEIGHT.
        SET f9_stage1_trajectory_button:TEXT TO "TRAJ ON".
        UpdateStage1TrajectoryGraph().
    } ELSE {
        f9_stage1_graph_box:HIDE().
        SET f9_stage1_gui:STYLE:HEIGHT TO F9_STAGE1_GUI_HEIGHT.
        SET f9_stage1_trajectory_button:TEXT TO "TRAJ OFF".
    }.

    SET F9_STAGE1_RUNTIME["ui_dirty"] TO TRUE.
}.

FUNCTION OnStage1TrajectoryPressed {
    IF F9_STAGE1_RUNTIME["trajectory_graph_visible"] {
        SetStage1TrajectoryGraphVisible(FALSE).
    } ELSE {
        SetStage1TrajectoryGraphVisible(TRUE).
    }.
}.

FUNCTION RecordStage1TrajectorySample {
    IF NOT F9_STAGE1_RUNTIME["live"] {
        RETURN.
    }.

    IF NOT F9_STAGE1_RUNTIME["trajectory_state"]:HASKEY("last_sample_time") {
        SET F9_STAGE1_RUNTIME["trajectory_state"]["last_sample_time"] TO -9999.
    }.

    IF TIME:SECONDS - F9_STAGE1_RUNTIME["trajectory_state"]["last_sample_time"] < 0.75 {
        RETURN.
    }.

    F9TrajectorySampleStage(F9_STAGE1_RUNTIME["trajectory_state"], "S1", 180).
    SET F9_STAGE1_RUNTIME["trajectory_state"]["last_sample_time"] TO TIME:SECONDS.
    SaveStage1TrajectoryState().
}.

FUNCTION EnsureStage1FuelBaseline {
    IF F9_STAGE1_RUNTIME["stage_fuel_start_units"] > 0 {
        RETURN.
    }.

    LOCAL currentUnits TO GetStage1FuelUnits().

    IF currentUnits > 0 {
        SET F9_STAGE1_RUNTIME["stage_fuel_start_units"] TO currentUnits.
    }.
}.

FUNCTION Stage1HasReachedMecoTarget {
    RETURN GetStage1FuelPercentRemaining() <= F9_STAGE1_RUNTIME["meco_fuel_percent"].
}.

FUNCTION ApplyStage1MecoCutoff {
    SET F9_STAGE1_RUNTIME["meco_reached"] TO TRUE.
    LOCK THROTTLE TO 0.
    SET F9_STAGE1_RUNTIME["status_text"] TO "MECO REACHED / SHUTDOWN".
    RCS ON.
    SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
    SET F9_STAGE1_RUNTIME["status_text"] TO "MECO REACHED / WAITING 3S FOR SEPARATION".
    SaveStage1MissionState().
    WAIT 3.
    SET F9_STAGE1_RUNTIME["handoff_phase"] TO "STAGE2_RELEASE".
    SaveStage1MissionState().
    STAGE.
    SET F9_STAGE1_RUNTIME["ui_dirty"] TO TRUE.
}.

FUNCTION BeginStage1Stabilization {
    IF F9_STAGE1_RUNTIME["stabilizing"] {
        RETURN.
    }.

    SET F9_STAGE1_RUNTIME["stabilizing"] TO TRUE.
    SET F9_STAGE1_RUNTIME["handoff_phase"] TO "STAGE2_PREP".
    LOCK STEERING TO SHIP:FACING.
    SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
    SET F9_STAGE1_RUNTIME["status_text"] TO "STABILIZING FOR STAGE 2 HANDOFF".
    SaveStage1MissionState().
    SET F9_STAGE1_RUNTIME["ui_dirty"] TO TRUE.
}.

FUNCTION UpdateStage1MaxQThrottle {
    IF F9_STAGE1_RUNTIME["meco_reached"] OR F9_STAGE1_RUNTIME["stabilizing"] {
        RETURN.
    }.

    LOCAL currentQ TO SHIP:Q.

    IF currentQ > F9_STAGE1_RUNTIME["max_q_peak"] {
        SET F9_STAGE1_RUNTIME["max_q_peak"] TO currentQ.
    }.

    IF NOT F9_STAGE1_RUNTIME["qbucket_active"] AND currentQ > GetStage1QBucketEntryThreshold() {
        SET F9_STAGE1_RUNTIME["qbucket_active"] TO TRUE.
        SET F9_STAGE1_RUNTIME["status_text"] TO "MAX-Q / THROTTLING DOWN".
        LOCK THROTTLE TO GetStage1MaxQThrottleTarget().
        SET F9_STAGE1_RUNTIME["throttle_target"] TO ROUND(GetStage1MaxQThrottleTarget() * 100, 0).
        SET F9_STAGE1_RUNTIME["ui_dirty"] TO TRUE.
        RETURN.
    }.

    IF F9_STAGE1_RUNTIME["qbucket_active"] {
        LOCK THROTTLE TO GetStage1MaxQThrottleTarget().
        SET F9_STAGE1_RUNTIME["throttle_target"] TO ROUND(GetStage1MaxQThrottleTarget() * 100, 0).

        IF currentQ < F9_STAGE1_RUNTIME["max_q_peak"] * 0.95 {
            SET F9_STAGE1_RUNTIME["qbucket_active"] TO FALSE.
            SET F9_STAGE1_RUNTIME["status_text"] TO "MAX-Q PASSED / THROTTLE RECOVERING".
            SET F9_STAGE1_RUNTIME["ui_dirty"] TO TRUE.
        }.
    }.
}.

FUNCTION GetStage1MissionState {
    IF EXISTS(F9_STAGE1_MISSION_STATE_PATH) {
        RETURN READJSON(F9_STAGE1_MISSION_STATE_PATH).
    }.

    RETURN LEXICON(
        "target_apoapsis_km", F9_STAGE1_RUNTIME["target_apoapsis_km"],
        "target_periapsis_km", F9_STAGE1_RUNTIME["target_periapsis_km"],
        "target_inclination_deg", F9_STAGE1_RUNTIME["target_inclination_deg"],
        "target_lan_deg", F9_STAGE1_RUNTIME["target_lan_deg"],
        "recovery_method", F9_STAGE1_RUNTIME["recovery_method"],
        "meco_fuel_percent", F9_STAGE1_RUNTIME["meco_fuel_percent"],
        "stage_fuel_start_units", 0,
        "stabilizing", FALSE,
        "handoff_phase", "IDLE",
        "selected_countdown_seconds", 360
    ).
}.

FUNCTION LoadStage1MissionState {
    LOCAL missionState TO GetStage1MissionState().

    SET F9_STAGE1_RUNTIME["target_apoapsis_km"] TO GetStage1StateOrDefault(missionState, "target_apoapsis_km", F9_STAGE1_RUNTIME["target_apoapsis_km"]).
    SET F9_STAGE1_RUNTIME["target_periapsis_km"] TO GetStage1StateOrDefault(missionState, "target_periapsis_km", F9_STAGE1_RUNTIME["target_periapsis_km"]).
    SET F9_STAGE1_RUNTIME["target_inclination_deg"] TO GetStage1StateOrDefault(missionState, "target_inclination_deg", F9_STAGE1_RUNTIME["target_inclination_deg"]).
    SET F9_STAGE1_RUNTIME["target_lan_deg"] TO GetStage1StateOrDefault(missionState, "target_lan_deg", F9_STAGE1_RUNTIME["target_lan_deg"]).
    SET F9_STAGE1_RUNTIME["recovery_method"] TO GetStage1StateOrDefault(missionState, "recovery_method", F9_STAGE1_RUNTIME["recovery_method"]).
    SET F9_STAGE1_RUNTIME["meco_fuel_percent"] TO GetStage1StateOrDefault(missionState, "meco_fuel_percent", GetStage1RecoveryMecoFuelPercent(F9_STAGE1_RUNTIME["recovery_method"])).
    SET F9_STAGE1_RUNTIME["stage_fuel_start_units"] TO 0.
    SET F9_STAGE1_RUNTIME["meco_reached"] TO FALSE.
    SET F9_STAGE1_RUNTIME["throttle_armed"] TO FALSE.
    SET F9_STAGE1_RUNTIME["qbucket_active"] TO FALSE.
    SET F9_STAGE1_RUNTIME["max_q_peak"] TO 0.
    SET F9_STAGE1_RUNTIME["stabilizing"] TO GetStage1StateOrDefault(missionState, "stabilizing", FALSE).
    SET F9_STAGE1_RUNTIME["handoff_phase"] TO GetStage1StateOrDefault(missionState, "handoff_phase", "IDLE").
}.

FUNCTION GetStage1LaunchAzimuth {
    PARAMETER targetApoapsisKm, desiredIncDeg.
    LOCAL targetAltM TO MAX(1000, targetApoapsisKm * 1000).
    LOCAL launchData TO LAZcalc_init(targetAltM, desiredIncDeg).

    RETURN LAZcalc(launchData).
}.

FUNCTION SetStage1WindowState {
    PARAMETER minimized.

    SET F9_STAGE1_RUNTIME["minimized"] TO minimized.

    IF minimized {
        f9_stage1_subtitle_label:HIDE().
        f9_stage1_mode_label:HIDE().
        f9_stage1_altitude_label:HIDE().
        f9_stage1_speed_label:HIDE().
        f9_stage1_pitch_label:HIDE().
        f9_stage1_throttle_label:HIDE().
        f9_stage1_status_label:HIDE().
        f9_stage1_trajectory_button:HIDE().
        f9_stage1_graph_box:HIDE().
        SET f9_stage1_gui:STYLE:HEIGHT TO F9_STAGE1_GUI_MIN_HEIGHT.
        SET f9_stage1_minimize_button:TEXT TO "RESTORE".
    } ELSE {
        f9_stage1_subtitle_label:SHOW().
        f9_stage1_mode_label:SHOW().
        f9_stage1_altitude_label:SHOW().
        f9_stage1_speed_label:SHOW().
        f9_stage1_pitch_label:SHOW().
        f9_stage1_throttle_label:SHOW().
        f9_stage1_status_label:SHOW().
        f9_stage1_trajectory_button:SHOW().
        IF F9_STAGE1_RUNTIME["trajectory_graph_visible"] {
            f9_stage1_graph_box:SHOW().
            SET f9_stage1_gui:STYLE:HEIGHT TO F9_STAGE1_GUI_HEIGHT + F9_STAGE1_GUI_GRAPH_EXTRA_HEIGHT.
        } ELSE {
            f9_stage1_graph_box:HIDE().
            SET f9_stage1_gui:STYLE:HEIGHT TO F9_STAGE1_GUI_HEIGHT.
        }.
        SET f9_stage1_minimize_button:TEXT TO "MIN".
    }.

    SET F9_STAGE1_RUNTIME["ui_dirty"] TO TRUE.
}.

FUNCTION ShowStage1GuiIfNeeded {
    IF F9_STAGE1_RUNTIME["ui_visible"] {
        RETURN.
    }.

    f9_stage1_gui:SHOW().
    SET F9_STAGE1_RUNTIME["ui_visible"] TO TRUE.
    SetStage1WindowState(FALSE).
}.

FUNCTION GetStage1PitchTarget {
    PARAMETER currentAlt.

    LOCAL targetApoapsisAlt TO MAX(90000, F9_STAGE1_RUNTIME["target_apoapsis_km"] * 1000).
    LOCAL turnStretch TO ClampNumber(targetApoapsisAlt / 150000, 1, 2.5).
    LOCAL pt1 TO 250.
    LOCAL pt2 TO 650 * turnStretch.
    LOCAL pt3 TO 1800 * turnStretch.
    LOCAL pt4 TO 4200 * turnStretch.
    LOCAL pt5 TO 8500 * turnStretch.
    LOCAL pt6 TO 16000 * turnStretch.
    LOCAL pt7 TO 28000 * turnStretch.
    LOCAL pt8 TO 44000 * turnStretch.
    LOCAL pt9 TO 65000 * turnStretch.

    IF currentAlt < pt1 {
        RETURN 90.
    }.

    IF currentAlt < pt2 {
        RETURN LerpNumber(90, 88, (currentAlt - pt1) / (pt2 - pt1)).
    }.

    IF currentAlt < pt3 {
        RETURN LerpNumber(88, 82, (currentAlt - pt2) / (pt3 - pt2)).
    }.

    IF currentAlt < pt4 {
        RETURN LerpNumber(82, 72, (currentAlt - pt3) / (pt4 - pt3)).
    }.

    IF currentAlt < pt5 {
        RETURN LerpNumber(72, 60, (currentAlt - pt4) / (pt5 - pt4)).
    }.

    IF currentAlt < pt6 {
        RETURN LerpNumber(60, 48, (currentAlt - pt5) / (pt6 - pt5)).
    }.

    IF currentAlt < pt7 {
        RETURN LerpNumber(48, 36, (currentAlt - pt6) / (pt7 - pt6)).
    }.

    IF currentAlt < pt8 {
        RETURN LerpNumber(36, 24, (currentAlt - pt7) / (pt8 - pt7)).
    }.

    IF currentAlt < pt9 {
        RETURN LerpNumber(24, 14, (currentAlt - pt8) / (pt9 - pt8)).
    }.

    RETURN 14.
}.

FUNCTION GetStage1ThrottleTarget {
    RETURN 1.
}.

FUNCTION GetStage1MaxQThrottleTarget {
    RETURN 0.72.
}.

FUNCTION GetStage1QBucketEntryThreshold {
    RETURN 22.
}.

FUNCTION LerpNumber {
    PARAMETER startValue, endValue, fraction.

    RETURN startValue + ((endValue - startValue) * ClampNumber(fraction, 0, 1)).
}.

FUNCTION BuildStage1Gui {
    LOCAL missionText TO SHIP:NAME.

    IF missionText = "" {
        SET missionText TO "FALCON 9 STAGE 1".
    }.

    GLOBAL f9_stage1_gui IS GUI(F9_STAGE1_GUI_WIDTH, F9_STAGE1_GUI_HEIGHT).
    SET f9_stage1_gui:X TO F9_STAGE1_GUI_X.
    SET f9_stage1_gui:Y TO F9_STAGE1_GUI_Y.
    SET f9_stage1_gui:STYLE:ALIGN TO "center".
    SET f9_stage1_gui:STYLE:HSTRETCH TO TRUE.
    SET f9_stage1_gui:skin:LABEL:TEXTCOLOR TO RGB(0.88, 0.95, 0.88).

    GLOBAL f9_stage1_title_box IS f9_stage1_gui:ADDHBOX().
    SET f9_stage1_title_box:STYLE:HEIGHT TO 28.

    GLOBAL f9_stage1_title_label IS f9_stage1_title_box:ADDLABEL("<b><size=17>" + F9_STAGE1_DEFAULT_TITLE + "</size></b>").
    SET f9_stage1_title_label:STYLE:TEXTCOLOR TO RGB(0.96, 0.84, 0.30).

    GLOBAL f9_stage1_mission_label IS f9_stage1_title_box:ADDLABEL("<size=13>" + missionText + "</size>").
    SET f9_stage1_mission_label:STYLE:ALIGN TO "right".
    SET f9_stage1_mission_label:STYLE:TEXTCOLOR TO RGB(0.80, 0.88, 0.92).

    f9_stage1_title_box:ADDSPACING(4).

    GLOBAL f9_stage1_minimize_button IS f9_stage1_title_box:ADDBUTTON("MIN").
    SET f9_stage1_minimize_button:STYLE:WIDTH TO 48.
    SET f9_stage1_minimize_button:STYLE:HEIGHT TO 22.
    SET f9_stage1_minimize_button:ONCLICK TO OnStage1MinimizePressed@.

    GLOBAL f9_stage1_close_button IS f9_stage1_title_box:ADDBUTTON("X").
    SET f9_stage1_close_button:STYLE:WIDTH TO 30.
    SET f9_stage1_close_button:STYLE:HEIGHT TO 22.
    SET f9_stage1_close_button:ONCLICK TO OnStage1ClosePressed@.

    GLOBAL f9_stage1_subtitle_label IS f9_stage1_gui:ADDLABEL("<size=11>" + F9_STAGE1_DEFAULT_SUBTITLE + "</size>").
    SET f9_stage1_subtitle_label:STYLE:ALIGN TO "center".
    SET f9_stage1_subtitle_label:STYLE:TEXTCOLOR TO RGB(0.74, 0.80, 0.85).

    f9_stage1_gui:ADDSPACING(3).

    GLOBAL f9_stage1_mode_label IS f9_stage1_gui:ADDLABEL("MODE: ARMED").
    SET f9_stage1_mode_label:STYLE:FONT TO "Consolas Bold".
    SET f9_stage1_mode_label:STYLE:FONTSIZE TO 15.
    SET f9_stage1_mode_label:STYLE:TEXTCOLOR TO RGB(0.82, 0.92, 0.86).

    GLOBAL f9_stage1_altitude_label IS f9_stage1_gui:ADDLABEL("ALTITUDE: 0 m").
    SET f9_stage1_altitude_label:STYLE:FONT TO "Consolas Bold".
    SET f9_stage1_altitude_label:STYLE:FONTSIZE TO 14.

    GLOBAL f9_stage1_speed_label IS f9_stage1_gui:ADDLABEL("SPEED: 0 m/s").
    SET f9_stage1_speed_label:STYLE:FONT TO "Consolas Bold".
    SET f9_stage1_speed_label:STYLE:FONTSIZE TO 14.

    GLOBAL f9_stage1_pitch_label IS f9_stage1_gui:ADDLABEL("PITCH TARGET: 90.0 DEG").
    SET f9_stage1_pitch_label:STYLE:FONT TO "Consolas Bold".
    SET f9_stage1_pitch_label:STYLE:FONTSIZE TO 14.

    GLOBAL f9_stage1_throttle_label IS f9_stage1_gui:ADDLABEL("THROTTLE TARGET: 0%").
    SET f9_stage1_throttle_label:STYLE:FONT TO "Consolas Bold".
    SET f9_stage1_throttle_label:STYLE:FONTSIZE TO 14.

    GLOBAL f9_stage1_recovery_label IS f9_stage1_gui:ADDLABEL("RECOVERY: RTLS / MECO 25.5%").
    SET f9_stage1_recovery_label:STYLE:FONT TO "Consolas Bold".
    SET f9_stage1_recovery_label:STYLE:FONTSIZE TO 14.

    GLOBAL f9_stage1_status_label IS f9_stage1_gui:ADDLABEL("STATUS: WAITING FOR LIFTOFF").
    SET f9_stage1_status_label:STYLE:FONT TO "Consolas Bold".
    SET f9_stage1_status_label:STYLE:FONTSIZE TO 13.
    SET f9_stage1_status_label:STYLE:TEXTCOLOR TO RGB(0.95, 0.84, 0.34).

    f9_stage1_gui:ADDSPACING(4).

    GLOBAL f9_stage1_button_box IS f9_stage1_gui:ADDHLAYOUT().
    SET f9_stage1_button_box:STYLE:WIDTH TO F9_STAGE1_GUI_WIDTH - 14.

    GLOBAL f9_stage1_guidance_button IS f9_stage1_button_box:ADDBUTTON("GUIDE").
    SET f9_stage1_guidance_button:STYLE:WIDTH TO 108.
    SET f9_stage1_guidance_button:STYLE:HEIGHT TO 26.
    SET f9_stage1_guidance_button:TOGGLE TO TRUE.
    SET f9_stage1_guidance_button:PRESSED TO TRUE.
    SET f9_stage1_guidance_button:ONTOGGLE TO OnStage1GuidanceToggled@.

    GLOBAL f9_stage1_free_button IS f9_stage1_button_box:ADDBUTTON("FREE").
    SET f9_stage1_free_button:STYLE:WIDTH TO 108.
    SET f9_stage1_free_button:STYLE:HEIGHT TO 26.
    SET f9_stage1_free_button:ONCLICK TO OnStage1FreePressed@.

    GLOBAL f9_stage1_rearm_button IS f9_stage1_button_box:ADDBUTTON("REARM").
    SET f9_stage1_rearm_button:STYLE:WIDTH TO 108.
    SET f9_stage1_rearm_button:STYLE:HEIGHT TO 26.
    SET f9_stage1_rearm_button:ONCLICK TO OnStage1RearmPressed@.

    GLOBAL f9_stage1_trajectory_button IS f9_stage1_button_box:ADDBUTTON("TRAJ OFF").
    SET f9_stage1_trajectory_button:STYLE:WIDTH TO 108.
    SET f9_stage1_trajectory_button:STYLE:HEIGHT TO 26.
    SET f9_stage1_trajectory_button:ONCLICK TO OnStage1TrajectoryPressed@.

    GLOBAL f9_stage1_graph_box IS f9_stage1_gui:ADDVBOX().
    SET f9_stage1_graph_box:STYLE:WIDTH TO F9_STAGE1_GUI_WIDTH - 14.
    SET f9_stage1_graph_box:STYLE:HEIGHT TO F9_STAGE1_GUI_GRAPH_EXTRA_HEIGHT - 10.
    f9_stage1_graph_box:HIDE().

    GLOBAL f9_stage1_graph_title_label IS f9_stage1_graph_box:ADDLABEL("<b><size=13>TRAJECTORY GRAPH</size></b>").
    SET f9_stage1_graph_title_label:STYLE:TEXTCOLOR TO RGB(0.96, 0.84, 0.30).

    GLOBAL f9_stage1_graph_label IS f9_stage1_graph_box:ADDLABEL("NO TRAJECTORY SAMPLES YET").
    SET f9_stage1_graph_label:STYLE:FONT TO "Consolas Bold".
    SET f9_stage1_graph_label:STYLE:FONTSIZE TO 10.
    SET f9_stage1_graph_label:STYLE:TEXTCOLOR TO RGB(0.82, 0.92, 0.86).

    f9_stage1_gui:HIDE().
}.

FUNCTION OnStage1GuidanceToggled {
    PARAMETER pressed.

    SET F9_STAGE1_RUNTIME["guidance_enabled"] TO pressed.

    IF pressed {
        SET F9_STAGE1_RUNTIME["status_text"] TO "GUIDANCE ENABLED".
    } ELSE {
        SET F9_STAGE1_RUNTIME["status_text"] TO "GUIDANCE DISABLED".
        UNLOCK STEERING.
        UNLOCK THROTTLE.
    }.

    SET F9_STAGE1_RUNTIME["ui_dirty"] TO TRUE.
}.

FUNCTION OnStage1FreePressed {
    SET F9_STAGE1_RUNTIME["guidance_enabled"] TO FALSE.
    SET F9_STAGE1_guidance_button:PRESSED TO FALSE.
    SET F9_STAGE1_RUNTIME["status_text"] TO "MANUAL CONTROL".
    UNLOCK STEERING.
    UNLOCK THROTTLE.
    SET F9_STAGE1_RUNTIME["ui_dirty"] TO TRUE.
}.

FUNCTION OnStage1RearmPressed {
    SET F9_STAGE1_RUNTIME["status_text"] TO "GUIDANCE REARMED".
    SET F9_STAGE1_RUNTIME["guidance_enabled"] TO TRUE.
    SET F9_STAGE1_guidance_button:PRESSED TO TRUE.
    SET F9_STAGE1_RUNTIME["ui_dirty"] TO TRUE.
}.

FUNCTION OnStage1MinimizePressed {
    IF F9_STAGE1_RUNTIME["ui_closed"] {
        RETURN.
    }.

    IF F9_STAGE1_RUNTIME["minimized"] {
        SetStage1WindowState(FALSE).
    } ELSE {
        SetStage1WindowState(TRUE).
    }.
}.

FUNCTION OnStage1ClosePressed {
    SET F9_STAGE1_RUNTIME["ui_closed"] TO TRUE.
    CLEARGUIS().
}.

FUNCTION SyncStage1Gui {
    PARAMETER forceRefresh.

    IF F9_STAGE1_RUNTIME["ui_closed"] {
        RETURN.
    }.

    LOCAL currentAltText TO "" + ROUND(SHIP:ALTITUDE, 0) + " m".
    LOCAL speedText TO "" + ROUND(SHIP:VERTICALSPEED, 0) + " m/s".
    LOCAL pitchTarget TO GetStage1PitchTarget(SHIP:ALTITUDE).
    LOCAL throttleTarget TO 0.

    IF F9_STAGE1_RUNTIME["live"] AND F9_STAGE1_RUNTIME["guidance_enabled"] {
        SET throttleTarget TO ROUND(GetStage1ThrottleTarget() * 100, 0).
    }.

    SET F9_STAGE1_RUNTIME["pitch_target"] TO pitchTarget.
    SET F9_STAGE1_RUNTIME["throttle_target"] TO throttleTarget.

    SET f9_stage1_mode_label:TEXT TO "MODE: " + F9_STAGE1_RUNTIME["mode"].
    SET f9_stage1_altitude_label:TEXT TO "ALTITUDE: " + currentAltText.
    SET f9_stage1_speed_label:TEXT TO "SPEED: " + speedText.
    SET f9_stage1_pitch_label:TEXT TO "PITCH TARGET: " + (ROUND(pitchTarget * 10, 0) / 10) + " DEG".
    SET f9_stage1_throttle_label:TEXT TO "THROTTLE TARGET: " + throttleTarget + "%".
    SET f9_stage1_recovery_label:TEXT TO "RECOVERY: " + F9_STAGE1_RUNTIME["recovery_method"] + " / MECO " + ROUND(F9_STAGE1_RUNTIME["meco_fuel_percent"], 1) + "%".
    SET f9_stage1_status_label:TEXT TO "STATUS: " + F9_STAGE1_RUNTIME["status_text"].

    IF F9_STAGE1_RUNTIME["guidance_enabled"] {
        SET f9_stage1_guidance_button:TEXT TO "GUIDE ON".
    } ELSE {
        SET f9_stage1_guidance_button:TEXT TO "GUIDE OFF".
    }.

    IF F9_STAGE1_RUNTIME["guidance_enabled"] {
        SET f9_stage1_free_button:ENABLED TO TRUE.
        SET f9_stage1_rearm_button:ENABLED TO TRUE.
    } ELSE {
        SET f9_stage1_free_button:ENABLED TO TRUE.
        SET f9_stage1_rearm_button:ENABLED TO TRUE.
    }.

    IF forceRefresh OR F9_STAGE1_RUNTIME["ui_dirty"] {
        SET F9_STAGE1_RUNTIME["ui_dirty"] TO FALSE.
    }.
}.

FUNCTION RunStage1Console {
    UNTIL FALSE {
        IF F9_STAGE1_RUNTIME["ui_closed"] {
            WAIT 0.2.
            CONTINUE.
        }.

        IF SHIP:STATUS <> "PRELAUNCH" {
            SET F9_STAGE1_RUNTIME["live"] TO TRUE.
            SET F9_STAGE1_RUNTIME["mode"] TO "ASCENT".
            ShowStage1GuiIfNeeded().
        }.

        IF NOT F9_STAGE1_RUNTIME["live"] {
            LoadStage1MissionState().
            EnsureStage1FuelBaseline().
        }.

        IF NOT F9_STAGE1_RUNTIME["meco_reached"] {
            EnsureStage1FuelBaseline().
        }.

        IF F9_STAGE1_RUNTIME["guidance_enabled"] AND NOT F9_STAGE1_RUNTIME["throttle_armed"] {
            LOCK THROTTLE TO 1.
            SET F9_STAGE1_RUNTIME["throttle_armed"] TO TRUE.
            SET F9_STAGE1_RUNTIME["throttle_target"] TO 100.
            SET F9_STAGE1_RUNTIME["status_text"] TO "THROTTLE ARMED / FULL POWER READY".
        }.

        IF NOT F9_STAGE1_RUNTIME["meco_reached"] AND NOT F9_STAGE1_RUNTIME["stabilizing"] {
            IF GetStage1FuelPercentRemaining() <= (F9_STAGE1_RUNTIME["meco_fuel_percent"] + 4) {
                BeginStage1Stabilization().
            }.
        }.

        IF NOT F9_STAGE1_RUNTIME["meco_reached"] {
            RCS OFF.
        }.

        IF F9_STAGE1_RUNTIME["live"] AND F9_STAGE1_RUNTIME["guidance_enabled"] {
            LOCAL targetPitch TO GetStage1PitchTarget(SHIP:ALTITUDE).
            LOCAL launchAzimuth TO GetStage1LaunchAzimuth(F9_STAGE1_RUNTIME["target_apoapsis_km"], F9_STAGE1_RUNTIME["target_inclination_deg"]).
            LOCAL maxPitchDrop TO 0.45.

            IF SHIP:ALTITUDE < 5000 {
                SET targetPitch TO MAX(targetPitch, 84).
                SET maxPitchDrop TO 0.2.
            } ELSE IF SHIP:ALTITUDE < 12000 {
                SET targetPitch TO MAX(targetPitch, 76).
                SET maxPitchDrop TO 0.3.
            } ELSE IF SHIP:ALTITUDE < 25000 {
                SET maxPitchDrop TO 0.35.
            }.

            SET F9_STAGE1_RUNTIME["smoothed_pitch_deg"] TO ClampNumber(
                F9_STAGE1_RUNTIME["smoothed_pitch_deg"] + ClampNumber(targetPitch - F9_STAGE1_RUNTIME["smoothed_pitch_deg"], -maxPitchDrop, maxPitchDrop),
                12,
                90
            ).
            SET F9_STAGE1_RUNTIME["pitch_target"] TO F9_STAGE1_RUNTIME["smoothed_pitch_deg"].

            IF NOT F9_STAGE1_RUNTIME["stabilizing"] {
                LOCK STEERING TO HEADING(launchAzimuth, F9_STAGE1_RUNTIME["smoothed_pitch_deg"], 180).
            }.
            IF F9_STAGE1_RUNTIME["meco_reached"] {
                LOCK THROTTLE TO 0.
                SET F9_STAGE1_RUNTIME["throttle_target"] TO 0.
                SET F9_STAGE1_RUNTIME["status_text"] TO "MECO COMPLETE / COASTING".
            } ELSE {
                LOCK THROTTLE TO 1.
                SET F9_STAGE1_RUNTIME["throttle_target"] TO 100.
                IF F9_STAGE1_RUNTIME["stabilizing"] {
                    SET F9_STAGE1_RUNTIME["status_text"] TO "STABILIZING / FULL THROTTLE".
                } ELSE {
                    SET F9_STAGE1_RUNTIME["status_text"] TO "FOLLOWING ASCENT PROFILE / AZIMUTH LOCKED / FULL THROTTLE".
                }.
            }.

            UpdateStage1MaxQThrottle().

            IF NOT F9_STAGE1_RUNTIME["meco_reached"] AND Stage1HasReachedMecoTarget() {
                ApplyStage1MecoCutoff().
            }.

            IF NOT F9_STAGE1_RUNTIME["meco_reached"] AND STAGE:READY AND STAGE:LIQUIDFUEL < 0.1 {
                SET F9_STAGE1_RUNTIME["status_text"] TO "STAGE READY / WAITING FOR NEXT HANDOFF".
            }.
        } ELSE {
            IF F9_STAGE1_RUNTIME["live"] {
                UNLOCK STEERING.
                UNLOCK THROTTLE.
                SET F9_STAGE1_RUNTIME["smoothed_pitch_deg"] TO 90.
                SET F9_STAGE1_RUNTIME["status_text"] TO "LIFTOFF DETECTED / GUIDANCE STANDBY".
            } ELSE {
                SET F9_STAGE1_RUNTIME["status_text"] TO "WAITING FOR LIFTOFF".
            }.
        }.

        RecordStage1TrajectorySample().
        UpdateStage1TrajectoryGraph().

        SyncStage1Gui(FALSE).
        WAIT 0.1.
    }.
}.
