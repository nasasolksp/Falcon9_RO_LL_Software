// Falcon 9 local copy of the KSLib launch azimuth helper.
// Source logic based on KSP-KOS/KSLib library/lib_lazcalc.ks.

@LAZYGLOBAL OFF.

FUNCTION LAZcalc_init {
    PARAMETER desiredAlt, desiredInc.
    PARAMETER autoNodeEpsilon IS 10.

    SET autoNodeEpsilon TO ABS(autoNodeEpsilon).

    LOCAL launchLatitude IS SHIP:LATITUDE.
    LOCAL data IS LIST().

    IF desiredAlt <= 0 {
        PRINT "Target altitude cannot be below sea level".
        SET launchAzimuth TO 1/0.
    }.

    LOCAL launchNode TO "Ascending".
    IF desiredInc < 0 {
        SET launchNode TO "Descending".
        SET desiredInc TO ABS(desiredInc).
    }.

    IF ABS(launchLatitude) > desiredInc {
        SET desiredInc TO ABS(launchLatitude).
    }.

    IF 180 - ABS(launchLatitude) < desiredInc {
        SET desiredInc TO 180 - ABS(launchLatitude).
    }.

    LOCAL equatorialVel IS (2 * CONSTANT():PI * SHIP:BODY:RADIUS) / SHIP:BODY:ROTATIONPERIOD.
    LOCAL targetOrbVel IS SQRT(SHIP:BODY:MU / (SHIP:BODY:RADIUS + desiredAlt)).
    data:ADD(desiredInc).
    data:ADD(launchLatitude).
    data:ADD(equatorialVel).
    data:ADD(targetOrbVel).
    data:ADD(launchNode).
    data:ADD(autoNodeEpsilon).
    RETURN data.
}.

FUNCTION LAZcalc {
    PARAMETER data.

    LOCAL inertialAzimuth IS ARCSIN(MAX(MIN(COS(data[0]) / COS(SHIP:LATITUDE), 1), -1)).
    LOCAL vxRot IS data[3] * SIN(inertialAzimuth) - data[2] * COS(data[1]).
    LOCAL vyRot IS data[3] * COS(inertialAzimuth).
    LOCAL azimuth IS MOD(ARCTAN2(vxRot, vyRot) + 360, 360).

    IF data[4] = "Ascending" {
        RETURN azimuth.
    } ELSE IF data[4] = "Descending" {
        IF azimuth <= 90 {
            RETURN 180 - azimuth.
        } ELSE IF azimuth >= 270 {
            RETURN 540 - azimuth.
        }.
    }.
}.
