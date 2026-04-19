@LAZYGLOBAL OFF.

GLOBAL F9_STAGE2_GUI_WIDTH IS 520.
GLOBAL F9_STAGE2_GUI_HEIGHT IS 300.
GLOBAL F9_STAGE2_GUI_MIN_HEIGHT IS 52.
GLOBAL F9_STAGE2_GUI_GRAPH_EXTRA_HEIGHT IS 220.
GLOBAL F9_STAGE2_GUI_X IS 246.
GLOBAL F9_STAGE2_GUI_Y IS 132.
GLOBAL F9_STAGE2_MISSION_STATE_PATH IS "0:/Falcon9/MISSION_STATE.json".
GLOBAL F9_STAGE2_TRAJECTORY_STATE_PATH IS "0:/Falcon9/MISSION_STATE.json".
RUNPATH("0:/Falcon9/F9_LAZcalc.ks").
RUNPATH("0:/Falcon9/F9_TRAJECTORY.ks").

GLOBAL F9_STAGE2_RUNTIME IS LEXICON(
    "ui_closed", FALSE,
    "ui_visible", FALSE,
    "minimized", FALSE,
    "live", FALSE,
    "handoff_phase", "IDLE",
    "stabilized", FALSE,
    "separation_started", FALSE,
    "burn_started", FALSE,
    "orbit_guidance_active", FALSE,
    "orbit_complete", FALSE,
    "fairings_staged", FALSE,
    "guidance_ready", FALSE,
    "guidance_start_apoapsis_m", 0,
    "target_apoapsis_km", 80,
    "target_periapsis_km", 80,
    "target_inclination_deg", 0,
    "target_lan_deg", 0,
    "current_pitch_deg", 0,
    "target_pitch_deg", 0,
    "current_throttle", 0,
    "smoothed_pitch_deg", 0,
    "smoothed_throttle", 0,
    "lookahead_apoapsis_m", 0,
    "eta_apoapsis_s", 0,
    "vertical_speed_ms", 0,
    "hold_pitch_deg", 12,
    "trajectory_graph_visible", FALSE,
    "trajectory_state", 0,
    "fore_push_seconds", 3,
    "status_text", "STANDBY",
    "ui_dirty", TRUE
).

GLOBAL f9_stage2_gui IS 0.
GLOBAL f9_stage2_title_label IS 0.
GLOBAL f9_stage2_mode_label IS 0.
GLOBAL f9_stage2_status_label IS 0.
GLOBAL f9_stage2_orbit_label IS 0.
GLOBAL f9_stage2_guidance_label IS 0.
GLOBAL f9_stage2_solution_label IS 0.
GLOBAL f9_stage2_button_box IS 0.
GLOBAL f9_stage2_trajectory_button IS 0.
GLOBAL f9_stage2_graph_box IS 0.
GLOBAL f9_stage2_graph_title_label IS 0.
GLOBAL f9_stage2_graph_label IS 0.
GLOBAL f9_stage2_minimize_button IS 0.
GLOBAL f9_stage2_close_button IS 0.

CLEARGUIS().
LoadStage2MissionState().
LoadStage2TrajectoryState().
BuildStage2Gui().
SyncStage2Gui(TRUE).
RunStage2Console().

FUNCTION GetStage2StateOrDefault {
    PARAMETER record, key, defaultValue.

    IF record:HASKEY(key) {
        RETURN record[key].
    }.

    RETURN defaultValue.
}.

FUNCTION GetStage2MissionState {
    IF EXISTS(F9_STAGE2_MISSION_STATE_PATH) {
        RETURN READJSON(F9_STAGE2_MISSION_STATE_PATH).
    }.

    RETURN LEXICON(
        "target_apoapsis_km", 80,
        "target_periapsis_km", 80,
        "target_inclination_deg", 0,
        "target_lan_deg", 0,
        "recovery_method", "RTLS",
        "meco_fuel_percent", 25.5,
        "stage_fuel_start_units", 0,
        "stabilizing", FALSE,
        "handoff_phase", "IDLE",
    "selected_countdown_seconds", 360
    ).
}.

FUNCTION LoadStage2MissionState {
    LOCAL missionState TO GetStage2MissionState().

    SET F9_STAGE2_RUNTIME["handoff_phase"] TO GetStage2StateOrDefault(missionState, "handoff_phase", F9_STAGE2_RUNTIME["handoff_phase"]).
    SET F9_STAGE2_RUNTIME["stabilized"] TO GetStage2StateOrDefault(missionState, "stabilizing", F9_STAGE2_RUNTIME["stabilized"]).
    SET F9_STAGE2_RUNTIME["target_apoapsis_km"] TO GetStage2StateOrDefault(missionState, "target_apoapsis_km", F9_STAGE2_RUNTIME["target_apoapsis_km"]).
    SET F9_STAGE2_RUNTIME["target_periapsis_km"] TO GetStage2StateOrDefault(missionState, "target_periapsis_km", F9_STAGE2_RUNTIME["target_periapsis_km"]).
    SET F9_STAGE2_RUNTIME["target_inclination_deg"] TO GetStage2StateOrDefault(missionState, "target_inclination_deg", F9_STAGE2_RUNTIME["target_inclination_deg"]).
    SET F9_STAGE2_RUNTIME["target_lan_deg"] TO GetStage2StateOrDefault(missionState, "target_lan_deg", F9_STAGE2_RUNTIME["target_lan_deg"]).
}.

FUNCTION SaveStage2MissionState {
    LOCAL missionState TO GetStage2MissionState().
    SET missionState["handoff_phase"] TO F9_STAGE2_RUNTIME["handoff_phase"].
    SET missionState["stabilizing"] TO F9_STAGE2_RUNTIME["stabilized"].
    SET missionState["target_apoapsis_km"] TO F9_STAGE2_RUNTIME["target_apoapsis_km"].
    SET missionState["target_periapsis_km"] TO F9_STAGE2_RUNTIME["target_periapsis_km"].
    SET missionState["target_inclination_deg"] TO F9_STAGE2_RUNTIME["target_inclination_deg"].
    SET missionState["target_lan_deg"] TO F9_STAGE2_RUNTIME["target_lan_deg"].

    WRITEJSON(missionState, F9_STAGE2_MISSION_STATE_PATH).
}.

FUNCTION GetStage2TrajectoryState {
    IF EXISTS(F9_STAGE2_TRAJECTORY_STATE_PATH) {
        LOCAL trajectoryState TO READJSON(F9_STAGE2_TRAJECTORY_STATE_PATH).

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

FUNCTION LoadStage2TrajectoryState {
    SET F9_STAGE2_RUNTIME["trajectory_state"] TO GetStage2TrajectoryState().
}.

FUNCTION SaveStage2TrajectoryState {
    LOCAL trajectoryState TO GetStage2TrajectoryState().
    SET trajectoryState["trajectory_samples"] TO F9_STAGE2_RUNTIME["trajectory_state"]["trajectory_samples"].
    SET trajectoryState["trajectory_origin_lat"] TO F9_STAGE2_RUNTIME["trajectory_state"]["trajectory_origin_lat"].
    SET trajectoryState["trajectory_origin_lng"] TO F9_STAGE2_RUNTIME["trajectory_state"]["trajectory_origin_lng"].
    SET trajectoryState["last_sample_time"] TO F9_STAGE2_RUNTIME["trajectory_state"]["last_sample_time"].
    WRITEJSON(trajectoryState, F9_STAGE2_TRAJECTORY_STATE_PATH).
}.

FUNCTION UpdateStage2TrajectoryGraph {
    IF NOT F9_STAGE2_RUNTIME["trajectory_graph_visible"] {
        RETURN.
    }.

    SET f9_stage2_graph_label:TEXT TO F9TrajectoryRender(F9_STAGE2_RUNTIME["trajectory_state"], "", 46, 14, "STAGE 2 TRAJECTORY").
    SET F9_STAGE2_RUNTIME["ui_dirty"] TO TRUE.
}.

FUNCTION SetStage2TrajectoryGraphVisible {
    PARAMETER visible.

    SET F9_STAGE2_RUNTIME["trajectory_graph_visible"] TO visible.

    IF visible {
        f9_stage2_graph_box:SHOW().
        SET f9_stage2_gui:STYLE:HEIGHT TO F9_STAGE2_GUI_HEIGHT + F9_STAGE2_GUI_GRAPH_EXTRA_HEIGHT.
        SET f9_stage2_trajectory_button:TEXT TO "TRAJ ON".
        UpdateStage2TrajectoryGraph().
    } ELSE {
        f9_stage2_graph_box:HIDE().
        SET f9_stage2_gui:STYLE:HEIGHT TO F9_STAGE2_GUI_HEIGHT.
        SET f9_stage2_trajectory_button:TEXT TO "TRAJ OFF".
    }.

    SET F9_STAGE2_RUNTIME["ui_dirty"] TO TRUE.
}.

FUNCTION OnStage2TrajectoryPressed {
    IF F9_STAGE2_RUNTIME["trajectory_graph_visible"] {
        SetStage2TrajectoryGraphVisible(FALSE).
    } ELSE {
        SetStage2TrajectoryGraphVisible(TRUE).
    }.
}.

FUNCTION RecordStage2TrajectorySample {
    IF NOT F9_STAGE2_RUNTIME["live"] AND NOT F9_STAGE2_RUNTIME["burn_started"] {
        RETURN.
    }.

    IF NOT F9_STAGE2_RUNTIME["trajectory_state"]:HASKEY("last_sample_time") {
        SET F9_STAGE2_RUNTIME["trajectory_state"]["last_sample_time"] TO -9999.
    }.

    IF TIME:SECONDS - F9_STAGE2_RUNTIME["trajectory_state"]["last_sample_time"] < 0.75 {
        RETURN.
    }.

    F9TrajectorySampleStage(F9_STAGE2_RUNTIME["trajectory_state"], "S2", 180).
    SET F9_STAGE2_RUNTIME["trajectory_state"]["last_sample_time"] TO TIME:SECONDS.
    SaveStage2TrajectoryState().
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

FUNCTION SmoothStep {
    PARAMETER value.

    LOCAL clampedValue TO ClampNumber(value, 0, 1).
    RETURN clampedValue * clampedValue * (3 - (2 * clampedValue)).
}.

FUNCTION LerpNumber {
    PARAMETER startValue, endValue, factor.

    RETURN startValue + ((endValue - startValue) * ClampNumber(factor, 0, 1)).
}.

FUNCTION GetStage2TargetOrbitMeters {
    PARAMETER targetKm.

    RETURN MAX(1000, targetKm * 1000).
}.

FUNCTION GetStage2LaunchAzimuth {
    PARAMETER targetApoapsisKm, desiredIncDeg.

    LOCAL targetAltM TO GetStage2TargetOrbitMeters(targetApoapsisKm).
    LOCAL launchData TO LAZcalc_init(targetAltM, desiredIncDeg).

    RETURN LAZcalc(launchData).
}.

FUNCTION GetStage2OrbitPitchTarget {
    PARAMETER targetApoM, targetPeriM, guidanceStartApoM.

    LOCAL apoNowM TO SHIP:ORBIT:APOAPSIS.
    LOCAL periNowM TO SHIP:ORBIT:PERIAPSIS.
    LOCAL verticalSpeedMs TO SHIP:VERTICALSPEED.
    LOCAL etaApoS TO MAX(0, ETA:APOAPSIS).
    LOCAL progressSpanM TO MAX(1, targetApoM - guidanceStartApoM).
    LOCAL apoProgress TO ClampNumber((apoNowM - guidanceStartApoM) / progressSpanM, 0, 1).
    LOCAL apoShortRatio TO ClampNumber((targetApoM - apoNowM) / MAX(1, targetApoM), -1, 1).
    LOCAL periShortRatio TO ClampNumber((targetPeriM - periNowM) / MAX(1, targetPeriM), -1, 1).
    LOCAL futureApoM TO apoNowM + (MAX(0, verticalSpeedMs) * etaApoS).
    LOCAL overshootRatio TO ClampNumber((futureApoM - targetApoM) / MAX(1, targetApoM), -1, 1).
    LOCAL targetPitch TO LerpNumber(20, 3, SmoothStep(apoProgress)).

    SET targetPitch TO targetPitch - (apoShortRatio * 6).
    SET targetPitch TO targetPitch - (periShortRatio * 4).
    SET targetPitch TO targetPitch + (overshootRatio * 8).

    IF verticalSpeedMs > 0 {
        SET targetPitch TO targetPitch + MIN(4, verticalSpeedMs / 120).
    } ELSE {
        SET targetPitch TO targetPitch + (verticalSpeedMs / 40).
    }.

    IF etaApoS > 27 AND targetPitch > 8 {
        SET targetPitch TO 8.
    }.

    IF etaApoS < 12 AND targetPitch > 10 {
        SET targetPitch TO targetPitch - 2.
    }.

    IF etaApoS < 8 AND targetPitch > 6 {
        SET targetPitch TO targetPitch - 1.
    }.

    RETURN ClampNumber(targetPitch, 0, 25).
}.

FUNCTION Stage2OrbitTargetReached {
    PARAMETER targetApoM, targetPeriM.

    RETURN SHIP:ORBIT:APOAPSIS >= targetApoM - 1500 AND SHIP:ORBIT:PERIAPSIS >= targetPeriM - 1500.
}.

FUNCTION Stage2OrbitUnrecoverable {
    PARAMETER targetApoM, targetPeriM, guidanceStartApoM.

    LOCAL apoNowM TO SHIP:ORBIT:APOAPSIS.
    LOCAL periNowM TO SHIP:ORBIT:PERIAPSIS.
    LOCAL verticalSpeedMs TO SHIP:VERTICALSPEED.
    LOCAL etaApoS TO MAX(0, ETA:APOAPSIS).
    LOCAL progressSpanM TO MAX(1, targetApoM - guidanceStartApoM).
    LOCAL progressRatio TO ClampNumber((apoNowM - guidanceStartApoM) / progressSpanM, 0, 1).
    LOCAL futureApoM TO apoNowM + (MAX(0, verticalSpeedMs) * etaApoS).
    LOCAL recoverableOvershootM TO MAX(8000, (MAX(0, verticalSpeedMs) * etaApoS) * 0.5) + (progressRatio * 2500).

    RETURN futureApoM > targetApoM + recoverableOvershootM AND periNowM < targetPeriM - 5000.
}.

FUNCTION Stage2JettisonFairingsIfNeeded {
    IF F9_STAGE2_RUNTIME["fairings_staged"] {
        RETURN.
    }.

    IF SHIP:ALTITUDE <= SHIP:BODY:ATM:HEIGHT {
        RETURN.
    }.

    IF NOT STAGE:READY {
        RETURN.
    }.

    STAGE.
    SET F9_STAGE2_RUNTIME["fairings_staged"] TO TRUE.
    SET F9_STAGE2_RUNTIME["status_text"] TO "FAIRINGS JETTISONED / ORBIT INSERTION CONTINUES".
    SET F9_STAGE2_RUNTIME["ui_dirty"] TO TRUE.
}.

FUNCTION SetStage2WindowState {
    PARAMETER minimized.

    SET F9_STAGE2_RUNTIME["minimized"] TO minimized.

    IF minimized {
        f9_stage2_mode_label:HIDE().
        f9_stage2_status_label:HIDE().
        f9_stage2_orbit_label:HIDE().
        f9_stage2_guidance_label:HIDE().
        f9_stage2_solution_label:HIDE().
        f9_stage2_button_box:HIDE().
        f9_stage2_graph_box:HIDE().
        SET f9_stage2_gui:STYLE:HEIGHT TO F9_STAGE2_GUI_MIN_HEIGHT.
        SET f9_stage2_minimize_button:TEXT TO "RESTORE".
    } ELSE {
        f9_stage2_mode_label:SHOW().
        f9_stage2_status_label:SHOW().
        f9_stage2_orbit_label:SHOW().
        f9_stage2_guidance_label:SHOW().
        f9_stage2_solution_label:SHOW().
        f9_stage2_button_box:SHOW().
        IF F9_STAGE2_RUNTIME["trajectory_graph_visible"] {
            f9_stage2_graph_box:SHOW().
            SET f9_stage2_gui:STYLE:HEIGHT TO F9_STAGE2_GUI_HEIGHT + F9_STAGE2_GUI_GRAPH_EXTRA_HEIGHT.
        } ELSE {
            f9_stage2_graph_box:HIDE().
            SET f9_stage2_gui:STYLE:HEIGHT TO F9_STAGE2_GUI_HEIGHT.
        }.
        SET f9_stage2_minimize_button:TEXT TO "MIN".
    }.

    SET F9_STAGE2_RUNTIME["ui_dirty"] TO TRUE.
}.

FUNCTION SetStage2Prepared {
    IF F9_STAGE2_RUNTIME["stabilized"] {
        RETURN.
    }.

    SET F9_STAGE2_RUNTIME["stabilized"] TO TRUE.
    SET F9_STAGE2_RUNTIME["status_text"] TO "STABILIZING / HOLDING CURRENT ATTITUDE".
    RCS OFF.
    LOCK STEERING TO SHIP:FACING.
    SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
    SaveStage2MissionState().
    SET F9_STAGE2_RUNTIME["ui_dirty"] TO TRUE.
}.

FUNCTION ExecuteStage2SeparationAndBurn {
    IF F9_STAGE2_RUNTIME["separation_started"] {
        RETURN.
    }.

    SET F9_STAGE2_RUNTIME["separation_started"] TO TRUE.
    SET F9_STAGE2_RUNTIME["status_text"] TO "SEPARATING / PUSHING FORE FOR 3 SECONDS".
    RCS ON.
    SET SHIP:CONTROL:NEUTRALIZE TO FALSE.
    LOCK STEERING TO SHIP:FACING.
    LOCK THROTTLE TO 0.
    SET SHIP:CONTROL:FORE TO 1.
    WAIT F9_STAGE2_RUNTIME["fore_push_seconds"].
    SET SHIP:CONTROL:FORE TO 0.
    LOCK STEERING TO SHIP:FACING.
    SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
    SET F9_STAGE2_RUNTIME["smoothed_throttle"] TO 1.
    LOCK THROTTLE TO 1.
    SET F9_STAGE2_RUNTIME["status_text"] TO "HOLDING ATTITUDE / THROTTLE ARMED / IGNITING IN 1 SECOND".
    WAIT 1.
    RCS OFF.
    LOCK STEERING TO SHIP:FACING.
    SET F9_STAGE2_RUNTIME["orbit_guidance_active"] TO TRUE.
    SET F9_STAGE2_RUNTIME["guidance_ready"] TO FALSE.
    LOCK THROTTLE TO 1.
    SET F9_STAGE2_RUNTIME["burn_started"] TO TRUE.
    SET F9_STAGE2_RUNTIME["status_text"] TO "STAGE 2 IGNITED / ORBIT INSERTION / WAITING FOR APOAPSIS".
    SET F9_STAGE2_RUNTIME["handoff_phase"] TO "STAGE2_ORBIT".
    SaveStage2MissionState().
    SET F9_STAGE2_RUNTIME["ui_dirty"] TO TRUE.
}.

FUNCTION UpdateStage2OrbitGuidance {
    IF NOT F9_STAGE2_RUNTIME["orbit_guidance_active"] {
        RETURN.
    }.

    IF F9_STAGE2_RUNTIME["orbit_complete"] {
        RETURN.
    }.

    LOCAL targetApoM TO GetStage2TargetOrbitMeters(F9_STAGE2_RUNTIME["target_apoapsis_km"]).
    LOCAL targetPeriM TO GetStage2TargetOrbitMeters(F9_STAGE2_RUNTIME["target_periapsis_km"]).
    LOCAL apoNowM TO SHIP:ORBIT:APOAPSIS.
    LOCAL periNowM TO SHIP:ORBIT:PERIAPSIS.
    LOCAL verticalSpeedMs TO SHIP:VERTICALSPEED.
    LOCAL etaApoS TO MAX(0, ETA:APOAPSIS).

    SET F9_STAGE2_RUNTIME["current_pitch_deg"] TO 90 - VANG(SHIP:UP:FOREVECTOR, SHIP:FACING:FOREVECTOR).
    SET F9_STAGE2_RUNTIME["current_throttle"] TO THROTTLE.
    SET F9_STAGE2_RUNTIME["vertical_speed_ms"] TO verticalSpeedMs.
    SET F9_STAGE2_RUNTIME["eta_apoapsis_s"] TO etaApoS.
    SET F9_STAGE2_RUNTIME["lookahead_apoapsis_m"] TO apoNowM + (MAX(0, verticalSpeedMs) * etaApoS).

    IF Stage2OrbitTargetReached(targetApoM, targetPeriM) {
        LOCK THROTTLE TO 0.
        SET F9_STAGE2_RUNTIME["orbit_complete"] TO TRUE.
        SET F9_STAGE2_RUNTIME["status_text"] TO "ORBIT TARGET REACHED / COASTING".
        SET F9_STAGE2_RUNTIME["handoff_phase"] TO "STAGE2_ORBIT_COMPLETE".
        SaveStage2MissionState().
        SET F9_STAGE2_RUNTIME["ui_dirty"] TO TRUE.
        RETURN.
    }.

    IF apoNowM < SHIP:BODY:ATM:HEIGHT + 2000 {
        SET F9_STAGE2_RUNTIME["guidance_ready"] TO FALSE.
        SET F9_STAGE2_RUNTIME["hold_pitch_deg"] TO ClampNumber(12 + (MAX(0, verticalSpeedMs) / 80), 10, 22).

        IF verticalSpeedMs < 0 {
            SET F9_STAGE2_RUNTIME["hold_pitch_deg"] TO ClampNumber(F9_STAGE2_RUNTIME["hold_pitch_deg"] + MIN(8, ABS(verticalSpeedMs) / 8), 12, 30).
        }.

        IF verticalSpeedMs < -10 {
            SET F9_STAGE2_RUNTIME["hold_pitch_deg"] TO ClampNumber(F9_STAGE2_RUNTIME["hold_pitch_deg"] + 4, 14, 32).
        }.

        LOCK STEERING TO HEADING(GetStage2LaunchAzimuth(F9_STAGE2_RUNTIME["target_apoapsis_km"], F9_STAGE2_RUNTIME["target_inclination_deg"]), F9_STAGE2_RUNTIME["hold_pitch_deg"], 180).
        LOCK THROTTLE TO 1.
        SET F9_STAGE2_RUNTIME["status_text"] TO "ORBIT PREP / BUILDING APOAPSIS / HOLDING POSITIVE PITCH".
        SET F9_STAGE2_RUNTIME["ui_dirty"] TO TRUE.
        RETURN.
    }.

    IF NOT F9_STAGE2_RUNTIME["guidance_ready"] {
        SET F9_STAGE2_RUNTIME["guidance_ready"] TO TRUE.
        SET F9_STAGE2_RUNTIME["guidance_start_apoapsis_m"] TO MAX(apoNowM, SHIP:BODY:ATM:HEIGHT + 2000).
        SET F9_STAGE2_RUNTIME["smoothed_pitch_deg"] TO 18.
        SET F9_STAGE2_RUNTIME["smoothed_throttle"] TO 1.
    }.

    IF Stage2OrbitUnrecoverable(targetApoM, targetPeriM, F9_STAGE2_RUNTIME["guidance_start_apoapsis_m"]) {
        LOCK THROTTLE TO 0.
        SET F9_STAGE2_RUNTIME["orbit_complete"] TO TRUE.
        SET F9_STAGE2_RUNTIME["status_text"] TO "APOAPSIS LIMIT EXCEEDED / COASTING".
        SET F9_STAGE2_RUNTIME["handoff_phase"] TO "STAGE2_ABORT".
        SaveStage2MissionState().
        SET F9_STAGE2_RUNTIME["ui_dirty"] TO TRUE.
        RETURN.
    }.

    LOCAL launchAzimuth TO GetStage2LaunchAzimuth(F9_STAGE2_RUNTIME["target_apoapsis_km"], F9_STAGE2_RUNTIME["target_inclination_deg"]).
    LOCAL targetPitch TO GetStage2OrbitPitchTarget(targetApoM, targetPeriM, F9_STAGE2_RUNTIME["guidance_start_apoapsis_m"]).
    LOCAL throttleTarget TO 1.

    IF apoNowM > targetApoM - 20000 OR periNowM > targetPeriM - 20000 {
        SET throttleTarget TO 0.7.
    }.

    IF apoNowM > targetApoM - 10000 AND periNowM > targetPeriM - 10000 {
        SET throttleTarget TO 0.45.
    }.

    IF apoNowM > targetApoM - 4000 AND periNowM > targetPeriM - 4000 {
        SET throttleTarget TO 0.2.
    }.

    IF F9_STAGE2_RUNTIME["lookahead_apoapsis_m"] > targetApoM + 5000 {
        SET throttleTarget TO MIN(throttleTarget, 0.45).
    }.

    IF F9_STAGE2_RUNTIME["lookahead_apoapsis_m"] > targetApoM + 12000 {
        SET throttleTarget TO MIN(throttleTarget, 0.25).
    }.

    IF verticalSpeedMs < 30 AND apoNowM > targetApoM - 10000 {
        SET throttleTarget TO MIN(throttleTarget, 0.35).
    }.

    SET F9_STAGE2_RUNTIME["target_pitch_deg"] TO targetPitch.
    SET F9_STAGE2_RUNTIME["smoothed_pitch_deg"] TO ClampNumber(F9_STAGE2_RUNTIME["smoothed_pitch_deg"] + ClampNumber(targetPitch - F9_STAGE2_RUNTIME["smoothed_pitch_deg"], -1.25, 1.25), 0, 25).
    SET F9_STAGE2_RUNTIME["smoothed_throttle"] TO ClampNumber(F9_STAGE2_RUNTIME["smoothed_throttle"] + ClampNumber(throttleTarget - F9_STAGE2_RUNTIME["smoothed_throttle"], -0.08, 0.08), 0.1, 1).

    LOCK STEERING TO HEADING(launchAzimuth, F9_STAGE2_RUNTIME["smoothed_pitch_deg"], 180).
    LOCK THROTTLE TO F9_STAGE2_RUNTIME["smoothed_throttle"].
    SET F9_STAGE2_RUNTIME["status_text"] TO "ORBIT INSERTION / APO " + ROUND(apoNowM / 1000, 1) + " km / PERI " + ROUND(periNowM / 1000, 1) + " km".
    SET F9_STAGE2_RUNTIME["ui_dirty"] TO TRUE.
}.

FUNCTION ShowStage2GuiIfNeeded {
    IF F9_STAGE2_RUNTIME["ui_visible"] {
        RETURN.
    }.

    f9_stage2_gui:SHOW().
    SET F9_STAGE2_RUNTIME["ui_visible"] TO TRUE.
    SetStage2WindowState(FALSE).
}.

FUNCTION BuildStage2Gui {
    GLOBAL f9_stage2_gui IS GUI(F9_STAGE2_GUI_WIDTH, F9_STAGE2_GUI_HEIGHT).
    SET f9_stage2_gui:X TO F9_STAGE2_GUI_X.
    SET f9_stage2_gui:Y TO F9_STAGE2_GUI_Y.
    SET f9_stage2_gui:STYLE:ALIGN TO "center".
    SET f9_stage2_gui:STYLE:HSTRETCH TO TRUE.

    GLOBAL f9_stage2_title_box IS f9_stage2_gui:ADDHBOX().
    SET f9_stage2_title_box:STYLE:HEIGHT TO 28.

    GLOBAL f9_stage2_title_label IS f9_stage2_title_box:ADDLABEL("<b><size=17>FALCON 9 STAGE 2</size></b>").
    SET f9_stage2_title_label:STYLE:TEXTCOLOR TO RGB(0.96, 0.84, 0.30).

    f9_stage2_title_box:ADDSPACING(4).

    GLOBAL f9_stage2_minimize_button IS f9_stage2_title_box:ADDBUTTON("MIN").
    SET f9_stage2_minimize_button:STYLE:WIDTH TO 48.
    SET f9_stage2_minimize_button:STYLE:HEIGHT TO 22.
    SET f9_stage2_minimize_button:ONCLICK TO OnStage2MinimizePressed@.

    GLOBAL f9_stage2_close_button IS f9_stage2_title_box:ADDBUTTON("X").
    SET f9_stage2_close_button:STYLE:WIDTH TO 30.
    SET f9_stage2_close_button:STYLE:HEIGHT TO 22.
    SET f9_stage2_close_button:ONCLICK TO OnStage2ClosePressed@.

    GLOBAL f9_stage2_mode_label IS f9_stage2_gui:ADDLABEL("MODE: STANDBY").
    SET f9_stage2_mode_label:STYLE:FONT TO "Consolas Bold".
    SET f9_stage2_mode_label:STYLE:FONTSIZE TO 15.
    SET f9_stage2_mode_label:STYLE:TEXTCOLOR TO RGB(0.82, 0.92, 0.86).

    GLOBAL f9_stage2_status_label IS f9_stage2_gui:ADDLABEL("STATUS: WAITING FOR STAGE 2 ACTIVE").
    SET f9_stage2_status_label:STYLE:FONT TO "Consolas Bold".
    SET f9_stage2_status_label:STYLE:FONTSIZE TO 13.
    SET f9_stage2_status_label:STYLE:TEXTCOLOR TO RGB(0.95, 0.84, 0.34).

    GLOBAL f9_stage2_orbit_label IS f9_stage2_gui:ADDLABEL("ORBIT: APO 0.0 km / PERI 0.0 km").
    SET f9_stage2_orbit_label:STYLE:FONT TO "Consolas Bold".
    SET f9_stage2_orbit_label:STYLE:FONTSIZE TO 12.
    SET f9_stage2_orbit_label:STYLE:TEXTCOLOR TO RGB(0.82, 0.92, 0.86).

    GLOBAL f9_stage2_guidance_label IS f9_stage2_gui:ADDLABEL("GUIDANCE: HOLDING").
    SET f9_stage2_guidance_label:STYLE:FONT TO "Consolas Bold".
    SET f9_stage2_guidance_label:STYLE:FONTSIZE TO 12.
    SET f9_stage2_guidance_label:STYLE:TEXTCOLOR TO RGB(0.82, 0.92, 0.86).

    GLOBAL f9_stage2_solution_label IS f9_stage2_gui:ADDLABEL("PITCH / THRUST: 0.0 DEG / 0%").
    SET f9_stage2_solution_label:STYLE:FONT TO "Consolas Bold".
    SET f9_stage2_solution_label:STYLE:FONTSIZE TO 12.
    SET f9_stage2_solution_label:STYLE:TEXTCOLOR TO RGB(0.82, 0.92, 0.86).

    GLOBAL f9_stage2_button_box IS f9_stage2_gui:ADDHLAYOUT().
    SET f9_stage2_button_box:STYLE:WIDTH TO F9_STAGE2_GUI_WIDTH - 14.

    GLOBAL f9_stage2_trajectory_button IS f9_stage2_button_box:ADDBUTTON("TRAJ OFF").
    SET f9_stage2_trajectory_button:STYLE:WIDTH TO 92.
    SET f9_stage2_trajectory_button:STYLE:HEIGHT TO 22.
    SET f9_stage2_trajectory_button:ONCLICK TO OnStage2TrajectoryPressed@.

    GLOBAL f9_stage2_graph_box IS f9_stage2_gui:ADDVBOX().
    SET f9_stage2_graph_box:STYLE:WIDTH TO F9_STAGE2_GUI_WIDTH - 14.
    SET f9_stage2_graph_box:STYLE:HEIGHT TO F9_STAGE2_GUI_GRAPH_EXTRA_HEIGHT - 10.
    f9_stage2_graph_box:HIDE().

    GLOBAL f9_stage2_graph_title_label IS f9_stage2_graph_box:ADDLABEL("<b><size=13>TRAJECTORY GRAPH</size></b>").
    SET f9_stage2_graph_title_label:STYLE:TEXTCOLOR TO RGB(0.96, 0.84, 0.30).

    GLOBAL f9_stage2_graph_label IS f9_stage2_graph_box:ADDLABEL("NO TRAJECTORY SAMPLES YET").
    SET f9_stage2_graph_label:STYLE:FONT TO "Consolas Bold".
    SET f9_stage2_graph_label:STYLE:FONTSIZE TO 10.
    SET f9_stage2_graph_label:STYLE:TEXTCOLOR TO RGB(0.82, 0.92, 0.86).

    f9_stage2_gui:SHOW().
    f9_stage2_gui:HIDE().
}.

FUNCTION OnStage2MinimizePressed {
    IF F9_STAGE2_RUNTIME["ui_closed"] {
        RETURN.
    }.

    IF F9_STAGE2_RUNTIME["minimized"] {
        SetStage2WindowState(FALSE).
    } ELSE {
        SetStage2WindowState(TRUE).
    }.
}.

FUNCTION OnStage2ClosePressed {
    SET F9_STAGE2_RUNTIME["ui_closed"] TO TRUE.
    CLEARGUIS().
}.

FUNCTION SyncStage2Gui {
    PARAMETER forceRefresh.

    IF F9_STAGE2_RUNTIME["ui_closed"] {
        RETURN.
    }.

    IF SHIP:STATUS <> "PRELAUNCH" AND STAGE:NUMBER <= 2 {
        SET F9_STAGE2_RUNTIME["live"] TO TRUE.
        SET F9_STAGE2_RUNTIME["status_text"] TO "STAGE 2 ACTIVE".
        ShowStage2GuiIfNeeded().
    }.

    LoadStage2MissionState().
    LoadStage2TrajectoryState().

    IF F9_STAGE2_RUNTIME["handoff_phase"] = "STAGE2_PREP" {
        SetStage2Prepared().
    }.

    IF F9_STAGE2_RUNTIME["handoff_phase"] = "STAGE2_RELEASE" {
        ExecuteStage2SeparationAndBurn().
    }.

    IF F9_STAGE2_RUNTIME["separation_started"] AND NOT F9_STAGE2_RUNTIME["burn_started"] {
        LOCK STEERING TO SHIP:FACING.
        LOCK THROTTLE TO 1.
    }.

    IF F9_STAGE2_RUNTIME["burn_started"] AND NOT F9_STAGE2_RUNTIME["orbit_complete"] {
        Stage2JettisonFairingsIfNeeded().
        UpdateStage2OrbitGuidance().
    }.

    RecordStage2TrajectorySample().
    UpdateStage2TrajectoryGraph().

    IF F9_STAGE2_RUNTIME["live"] {
        SET f9_stage2_mode_label:TEXT TO "MODE: ACTIVE".
    } ELSE {
        SET f9_stage2_mode_label:TEXT TO "MODE: STANDBY".
    }.
    SET f9_stage2_status_label:TEXT TO "STATUS: " + F9_STAGE2_RUNTIME["status_text"].
    SET f9_stage2_orbit_label:TEXT TO "ORBIT: APO " + ROUND(SHIP:ORBIT:APOAPSIS / 1000, 1) + " km / PERI " + ROUND(SHIP:ORBIT:PERIAPSIS / 1000, 1) + " km / VS " + ROUND(F9_STAGE2_RUNTIME["vertical_speed_ms"], 1) + " m/s".
    IF F9_STAGE2_RUNTIME["guidance_ready"] {
        SET f9_stage2_guidance_label:TEXT TO "GUIDANCE: ACTIVE / AZ " + ROUND(GetStage2LaunchAzimuth(F9_STAGE2_RUNTIME["target_apoapsis_km"], F9_STAGE2_RUNTIME["target_inclination_deg"]), 1) + " / ETA APO " + ROUND(F9_STAGE2_RUNTIME["eta_apoapsis_s"], 0) + "s".
    } ELSE {
        SET f9_stage2_guidance_label:TEXT TO "GUIDANCE: HOLDING / WAITING FOR APO > ATM + 2 KM".
    }.
    SET f9_stage2_solution_label:TEXT TO "PITCH / THRUST: " + ROUND(F9_STAGE2_RUNTIME["smoothed_pitch_deg"], 1) + " DEG / " + ROUND(F9_STAGE2_RUNTIME["smoothed_throttle"] * 100, 0) + "% / HOLD " + ROUND(F9_STAGE2_RUNTIME["hold_pitch_deg"], 1) + " DEG / LOOKAHEAD APO " + ROUND(F9_STAGE2_RUNTIME["lookahead_apoapsis_m"] / 1000, 1) + " km".

    IF forceRefresh OR F9_STAGE2_RUNTIME["ui_dirty"] {
        SET F9_STAGE2_RUNTIME["ui_dirty"] TO FALSE.
    }.
}.

FUNCTION RunStage2Console {
    UNTIL FALSE {
        IF F9_STAGE2_RUNTIME["ui_closed"] {
            WAIT 0.2.
            CONTINUE.
        }.

        SyncStage2Gui(FALSE).
        WAIT 0.1.
    }.
}.
