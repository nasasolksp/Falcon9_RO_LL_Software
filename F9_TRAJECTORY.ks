@LAZYGLOBAL OFF.

FUNCTION F9TrajectoryClampNumber {
    PARAMETER value, minValue, maxValue.

    IF value < minValue {
        RETURN minValue.
    }.

    IF value > maxValue {
        RETURN maxValue.
    }.

    RETURN value.
}.

FUNCTION F9TrajectoryGetOriginLat {
    PARAMETER missionState.

    IF missionState:HASKEY("trajectory_origin_lat") {
        RETURN missionState["trajectory_origin_lat"].
    }.

    RETURN SHIP:LATITUDE.
}.

FUNCTION F9TrajectoryGetOriginLng {
    PARAMETER missionState.

    IF missionState:HASKEY("trajectory_origin_lng") {
        RETURN missionState["trajectory_origin_lng"].
    }.

    RETURN SHIP:LONGITUDE.
}.

FUNCTION F9TrajectoryEnsureOrigin {
    PARAMETER missionState.

    IF NOT missionState:HASKEY("trajectory_origin_lat") {
        SET missionState["trajectory_origin_lat"] TO SHIP:LATITUDE.
    }.

    IF NOT missionState:HASKEY("trajectory_origin_lng") {
        SET missionState["trajectory_origin_lng"] TO SHIP:LONGITUDE.
    }.
}.

FUNCTION F9TrajectoryDownrangeKm {
    PARAMETER originLatDeg, originLngDeg.

    LOCAL a TO SIN((SHIP:LATITUDE - originLatDeg) / 2)^2 + COS(originLatDeg) * COS(SHIP:LATITUDE) * SIN((SHIP:LONGITUDE - originLngDeg) / 2)^2.
    LOCAL arcDeg TO 2 * ARCTAN2(SQRT(a), SQRT(MAX(0, 1 - a))).

    RETURN (SHIP:BODY:RADIUS * CONSTANT:PI * arcDeg) / 90 / 1000.
}.

FUNCTION F9TrajectorySampleStage {
    PARAMETER missionState, stageTag, maxSamples.

    IF NOT missionState:HASKEY("trajectory_samples") {
        SET missionState["trajectory_samples"] TO LIST().
    }.

    F9TrajectoryEnsureOrigin(missionState).

    LOCAL samples TO missionState["trajectory_samples"].
    LOCAL originLat TO F9TrajectoryGetOriginLat(missionState).
    LOCAL originLng TO F9TrajectoryGetOriginLng(missionState).
    LOCAL sample TO LEXICON(
        "stage", stageTag,
        "downrange_km", F9TrajectoryDownrangeKm(originLat, originLng),
        "altitude_km", SHIP:ALTITUDE / 1000,
        "time_s", TIME:SECONDS
    ).

    samples:ADD(sample).

    IF samples:LENGTH > maxSamples {
        LOCAL pruned TO LIST().
        LOCAL startIndex TO samples:LENGTH - maxSamples.
        LOCAL idx TO startIndex.

        UNTIL idx >= samples:LENGTH {
            pruned:ADD(samples[idx]).
            SET idx TO idx + 1.
        }.

        SET missionState["trajectory_samples"] TO pruned.
    } ELSE {
        SET missionState["trajectory_samples"] TO samples.
    }.
}.

FUNCTION F9TrajectoryStamp {
    PARAMETER rowText, x, symbol.

    IF x < 0 {
        RETURN rowText.
    }.

    IF x > rowText:LENGTH - 1 {
        RETURN rowText.
    }.

    LOCAL leftPart TO rowText:SUBSTRING(0, x).
    LOCAL rightLen TO rowText:LENGTH - x - 1.
    LOCAL rightPart TO "".

    IF rightLen > 0 {
        SET rightPart TO rowText:SUBSTRING(x + 1, rightLen).
    }.

    RETURN leftPart + symbol + rightPart.
}.

FUNCTION F9TrajectoryRender {
    PARAMETER missionState, filterStage, width, height, titleText.

    LOCAL samples TO LIST().
    LOCAL sourceSamples TO LIST().
    LOCAL maxDownrangeKm TO 1.
    LOCAL maxAltitudeKm TO 1.
    LOCAL newline TO CHAR(10).
    LOCAL output TO titleText + newline.
    LOCAL y TO 0.

    IF missionState:HASKEY("trajectory_samples") {
        SET sourceSamples TO missionState["trajectory_samples"].
    }.

    LOCAL i TO 0.
    UNTIL i >= sourceSamples:LENGTH {
        LOCAL sample TO sourceSamples[i].
        IF filterStage = "" OR sample["stage"] = filterStage {
            samples:ADD(sample).
            IF sample["downrange_km"] > maxDownrangeKm {
                SET maxDownrangeKm TO sample["downrange_km"].
            }.
            IF sample["altitude_km"] > maxAltitudeKm {
                SET maxAltitudeKm TO sample["altitude_km"].
            }.
        }.
        SET i TO i + 1.
    }.

    IF samples:LENGTH = 0 {
        RETURN titleText + newline + "(no trajectory samples yet)".
    }.

    LOCAL rows TO LIST().
    LOCAL prevX TO -1.
    LOCAL prevRowIndex TO -1.
    LOCAL havePrev TO FALSE.
    UNTIL y >= height {
        LOCAL rowText TO "".
        LOCAL charIndex TO 0.
        UNTIL charIndex >= width {
            SET rowText TO rowText + " ".
            SET charIndex TO charIndex + 1.
        }.
        rows:ADD(rowText).
        SET y TO y + 1.
    }.

    SET i TO 0.
    UNTIL i >= samples:LENGTH {
        LOCAL sample TO samples[i].
        LOCAL x TO ROUND((sample["downrange_km"] / maxDownrangeKm) * (width - 1), 0).
        LOCAL plotY TO ROUND((sample["altitude_km"] / maxAltitudeKm) * (height - 1), 0).
        LOCAL rowIndex TO height - 1 - plotY.
        LOCAL pointSymbol TO ".".

        IF filterStage = "" AND sample["stage"] = "S2" {
            SET pointSymbol TO "*".
        }.

        IF x < 0 {
            SET x TO 0.
        }.

        IF x > width - 1 {
            SET x TO width - 1.
        }.

        IF havePrev {
            LOCAL dx TO x - prevX.
            LOCAL dy TO rowIndex - prevRowIndex.
            LOCAL absDx TO dx.
            LOCAL absDy TO dy.

            IF absDx < 0 {
                SET absDx TO -absDx.
            }.

            IF absDy < 0 {
                SET absDy TO -absDy.
            }.

            LOCAL steps TO absDx.
            IF absDy > steps {
                SET steps TO absDy.
            }.

            IF steps < 1 {
                SET steps TO 1.
            }.

            LOCAL stepIndex TO 1.
            UNTIL stepIndex > steps {
                LOCAL t TO stepIndex / steps.
                LOCAL drawX TO ROUND(prevX + (dx * t), 0).
                LOCAL drawRowIndex TO ROUND(prevRowIndex + (dy * t), 0).

                IF drawX < 0 {
                    SET drawX TO 0.
                }.

                IF drawX > width - 1 {
                    SET drawX TO width - 1.
                }.

                IF drawRowIndex < 0 {
                    SET drawRowIndex TO 0.
                }.

                IF drawRowIndex > height - 1 {
                    SET drawRowIndex TO height - 1.
                }.

                SET rows[drawRowIndex] TO F9TrajectoryStamp(rows[drawRowIndex], drawX, ".").
                SET stepIndex TO stepIndex + 1.
            }.
        }.

        SET rows[rowIndex] TO F9TrajectoryStamp(rows[rowIndex], x, pointSymbol).
        SET prevX TO x.
        SET prevRowIndex TO rowIndex.
        SET havePrev TO TRUE.
        SET i TO i + 1.
    }.

    SET i TO 0.
    UNTIL i >= rows:LENGTH {
        SET output TO output + rows[i] + newline.
        SET i TO i + 1.
    }.

    SET output TO output + "DR " + ROUND(samples[samples:LENGTH - 1]["downrange_km"], 1) + " km / ALT " + ROUND(samples[samples:LENGTH - 1]["altitude_km"], 1) + " km".
    RETURN output.
}.
