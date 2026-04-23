#!/usr/bin/env python3
from __future__ import annotations

import math
import re


def normalize(text: str) -> str:
    text = text.lower()
    text = text.replace("’", "'").replace("–", "-").replace("−", "-")
    text = text.replace("o.0", "10.0")
    text = text.replace("thepressure", "the pressure")
    text = text.replace("rangeof", "range of ")
    text = text.replace("variationof", "variation of ")
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def compact(text: str) -> str:
    return re.sub(r"\s+", "", normalize(text))


def contains(blob: str, tight: str, phrase: str) -> bool:
    normalized_phrase = normalize(phrase)
    return normalized_phrase in blob or normalized_phrase.replace(" ", "") in tight


def has_any(blob: str, tight: str, phrases) -> bool:
    return any(contains(blob, tight, phrase) for phrase in phrases)


def has_all(blob: str, tight: str, phrases) -> bool:
    return all(contains(blob, tight, phrase) for phrase in phrases)


def find_number(pattern: str, text: str) -> float | None:
    match = re.search(pattern, text)
    if not match:
        return None
    try:
        raw = match.group(1) if match.lastindex else match.group(0)
        raw = raw.replace(" ", "").replace(",", "")
        return float(raw)
    except ValueError:
        return None


def format_sig(value: float) -> str:
    if value == 0:
        return "0"
    abs_value = abs(value)
    if abs_value >= 1000:
        return f"{value:.0f}"
    if abs_value >= 100:
        return f"{value:.1f}".rstrip("0").rstrip(".")
    if abs_value >= 10:
        return f"{value:.2f}".rstrip("0").rstrip(".")
    return f"{value:.3f}".rstrip("0").rstrip(".")


def first_number(text: str, patterns, default: float | None = None) -> float | None:
    for pattern in patterns:
        value = find_number(pattern, text)
        if value is not None:
            return value
    return default


def context_phrase(blob: str, tight: str, topic: str) -> str:
    hints = [
        (["projectile", "thrown", "top of a building"], "projectile-motion"),
        (["velocity-time", "displacement-time", "distance-time", "acceleration of an object"], "motion-graph"),
        (["momentum-time", "momentum of the block", "momentum p"], "momentum-graph"),
        (["collision", "explodes", "fragments", "train carriages"], "momentum"),
        (["thermistor", "light-dependent resistor", "potential divider"], "sensor-circuit"),
        (["kirchhoff", "parallel circuit", "series circuit"], "circuit-law"),
        (["i-v", "current-voltage", "filament lamp", "semiconductor diode"], "i-v-characteristic"),
        (["oscilloscope", "cro", "time-base", "y-gain"], "oscilloscope"),
        (["loudspeaker", "whistle", "doppler"], "sound-wave"),
        (["doorway", "diffract", "diffraction"], "diffraction"),
        (["guitar string", "string is plucked"], "wave-type"),
        (["plate", "beneath the surface", "liquid"], "hydrostatic-pressure"),
        (["spring", "elastic limit", "young modulus", "wire is stretched"], "elasticity"),
        (["motor", "efficiency", "useful output power"], "power-and-efficiency"),
        (["radioactivity", "half-life", "alpha", "beta", "gamma"], "radioactivity"),
        (["quark", "lepton", "hadron", "meson", "baryon"], "particle-classification"),
        (["jupiter", "radio wave"], "electromagnetic-wave"),
    ]

    for phrases, label in hints:
        if has_any(blob, tight, phrases):
            return label

    if topic.startswith("Physical quantities and units"):
        return "units-and-measurements"
    if topic.startswith("Kinematics and acceleration"):
        return "kinematics"
    if topic.startswith("Forces and momentum"):
        return "forces-and-momentum"
    if topic.startswith("Matter and materials"):
        return "materials"
    if topic.startswith("Work, energy and power"):
        return "energy"
    if topic.startswith("Electricity and circuits"):
        return "electricity"
    if topic.startswith("Waves"):
        return "waves"
    if topic.startswith("Atomic and particle physics"):
        return "atomic-physics"
    return "physics"


def explanation_for(text: str, topic: str, answer: str) -> str:
    blob = normalize(text)
    tight = compact(text)

    if has_all(blob, tight, ["storage capacity", "gb", "byte"]):
        capacity = first_number(blob, [r"storage capacity of ([0-9.]+)\s*gb"], 128.0)
        bytes_value = capacity * 1e9
        mantissa, exponent = f"{bytes_value:.2e}".split("e")
        return (
            f"Use the decimal data prefix: 1 GB = 10^9 B. So {format_sig(capacity)} GB = {mantissa} × 10^{int(exponent)} B, "
            f"which matches option {answer}."
        )

    if contains(blob, tight, "what represents a physical quantity"):
        return (
            f"A physical quantity needs both a number and a unit. The correct choice is the only option that includes a numerical value "
            f"together with a valid physical unit, so option {answer} is right."
        )

    if contains(blob, tight, "could not be a measurement of a physical quantity"):
        return (
            f"Simplify each compound unit and check whether it corresponds to a real physical quantity. The odd one out is the option "
            f"whose unit combination does not represent a valid quantity, so option {answer} is correct."
        )

    if has_all(blob, tight, ["average speed", "average velocity"]):
        return (
            f"Average speed uses total distance travelled, but average velocity uses displacement divided by time. Compare the path length "
            f"with the straight-line displacement and that leads to option {answer}."
        )

    if has_all(blob, tight, ["air resistance", "vertically upwards"]):
        return (
            f"As the object rises, its speed decreases, so the air resistance also decreases. Weight stays constant, so the resultant "
            f"downward force becomes smaller as it moves up. That matches option {answer}."
        )

    if has_all(blob, tight, ["uniform acceleration", "fixed mass", "initially at rest"]):
        return (
            f"For a fixed mass, Newton's second law gives F = ma. Uniform acceleration means a is constant, so the resultant force is "
            f"constant and not zero. That is option {answer}."
        )

    if has_all(blob, tight, ["initial velocity u", "uniform acceleration a", "final velocity v"]):
        return (
            f"This is the standard constant-acceleration relation. The correct equation linking initial velocity, final velocity, "
            f"acceleration and time is v = u + at, so option {answer} is correct."
        )

    if has_all(blob, tight, ["variation with time of the velocity", "constant resultant force"]) and contains(blob, tight, "cm s-1"):
        force = first_number(blob, [r"force of ([0-9.]+)\s*n"], 300.0)
        time = first_number(blob, [r"for ([0-9.]+)\s*s"], 5.0)
        final_speed_cm = first_number(blob, [r"180", r"150", r"120"], 150.0)
        acceleration = (final_speed_cm / 100) / time
        mass = force / acceleration
        return (
            f"Read the final speed from the graph and convert it from cm s^-1 to m s^-1 before using a = Δv / Δt. Then apply F = ma, "
            f"so m = {format_sig(force)} / {format_sig(acceleration)} ≈ {format_sig(mass)} kg. That gives option {answer}."
        )

    if has_all(blob, tight, ["top of a building", "horizontal velocity", "hits the horizontal ground"]):
        height = first_number(blob, [r"height of the building is ([0-9.]+)\s*m"], 8.0)
        time = math.sqrt(2 * height / 9.81)
        return (
            f"The time to hit the ground depends only on the vertical motion because the initial vertical speed is zero. Use "
            f"s = 1/2 gt^2 with s = {format_sig(height)} m, giving t ≈ {format_sig(time)} s, so option {answer} is correct."
        )

    if has_all(blob, tight, ["golf ball", "horizontal and vertical components"]):
        return (
            f"With air resistance ignored, there is no horizontal acceleration, so the horizontal component of velocity stays constant. "
            f"The vertical acceleration is always g downward. That corresponds to option {answer}."
        )

    if has_all(blob, tight, ["projected from horizontal ground", "angle", "horizontal"]) and contains(blob, tight, "does not describe"):
        return (
            f"For projectile motion without air resistance, the horizontal velocity stays equal to u cos(theta), but the horizontal "
            f"distance travelled is u cos(theta) multiplied by the time of flight. The statement that misses the time factor is the "
            f"incorrect one, so option {answer} is right."
        )

    if has_all(blob, tight, ["radio wave", "jupiter"]):
        return (
            f"The stated time is for the pulse to travel to Jupiter and back, so the one-way distance is ct / 2. Using "
            f"c = 3.00 × 10^8 m s^-1 and t = 3960 s gives 5.94 × 10^11 m = 5.94 × 10^8 km, so option {answer} is correct."
        )

    if has_any(blob, tight, ["progressive waves", "all types of progressive wave"]):
        return (
            f"A progressive wave transfers energy from one place to another. It is not always transverse and it can exist in more than one "
            f"medium, so the correct general statement is option {answer}."
        )

    if has_all(blob, tight, ["blue whales", "range of wavelengths"]):
        wave_speed = first_number(blob, [r"approximately ([0-9.]+)\s*km\s*s-1"], 1.5) * 1000
        f_low = first_number(blob, [r"is ([0-9.]+)\s*hz to"], 10.0)
        f_high = first_number(blob, [r"to ([0-9.]+)\s*hz"], 40.0)
        lam_max = wave_speed / f_low
        lam_min = wave_speed / f_high
        return (
            f"Use v = f lambda, so lambda = v / f. The lowest frequency gives the largest wavelength and the highest frequency gives "
            f"the smallest: {format_sig(wave_speed)} / {format_sig(f_low)} = {format_sig(lam_max)} m and "
            f"{format_sig(wave_speed)} / {format_sig(f_high)} = {format_sig(lam_min)} m. That matches option {answer}."
        )

    if has_all(blob, tight, ["hear the highest frequency", "whistle"]) or has_all(blob, tight, ["swing", "highest frequency"]):
        return (
            f"This is a Doppler-effect question. The observed frequency is highest when the source is moving towards the observer with "
            f"the greatest speed, so the correct position and direction correspond to option {answer}."
        )

    if has_all(blob, tight, ["frequency of the sound heard", "travelling at a constant velocity directly towards a man"]):
        return (
            f"When a source moves towards an observer, the observer hears a higher frequency than the emitted frequency. The source still "
            f"emits its original frequency, so the correct statement is option {answer}."
        )

    if has_all(blob, tight, ["diffract", "doorway", "frequency of sound wave"]):
        return (
            f"Diffraction is greatest for the longest wavelength. Since lambda = v / f and the wave speed is fixed, the lowest "
            f"frequency has the largest wavelength and diffracts the most. That gives option {answer}."
        )

    if has_all(blob, tight, ["observer stands at a point", "meet in phase"]) and has_any(blob, tight, ["two loudspeakers", "x and y emit sound waves"]):
        return (
            f"For the waves to arrive in phase, the path difference must be a whole number of wavelengths. Compare the two distances to the "
            f"observer and choose the pair that gives an integer multiple of the wavelength. That is option {answer}."
        )

    if has_all(blob, tight, ["intensity of the sound is halved", "frequency remains constant"]):
        return (
            f"Wave intensity is proportional to amplitude squared. So halving the intensity reduces the amplitude by a factor of 1 / sqrt(2), "
            f"while the frequency and period stay the same. That identifies option {answer}."
        )

    if has_all(blob, tight, ["stationary sound wave", "microphone", "distance between x and y"]):
        return (
            f"When the CRO amplitude goes from a minimum to the next maximum, the microphone has moved from a node to the nearest "
            f"antinode, which is one quarter of a wavelength. Use that spacing first to find lambda, then use v = f lambda to reach "
            f"option {answer}."
        )

    if has_all(blob, tight, ["two large speakers", "loudest sound heard"]) or has_all(blob, tight, ["same wavelength", "same amplitude", "wavefronts"]):
        return (
            f"The loudest sound occurs at constructive interference, where the path difference from the two speakers is a whole number of "
            f"wavelengths. Choose the point where the waves arrive in phase, giving option {answer}."
        )

    if has_all(blob, tight, ["transverse wave", "longitudinal wave", "not correct"]):
        return (
            f"For both waves, wavelength is measured along the direction the wave travels, not along the direction of particle displacement. "
            f"So the incorrect statement is the one that gets that geometry wrong, which is option {answer}."
        )

    if has_all(blob, tight, ["jet aircraft", "directly approaches a stationary observer"]):
        return (
            f"For a moving source approaching a stationary observer, use the Doppler relation f' = fv / (v - v_s). With v_s = 0.80v, "
            f"the frequency becomes five times larger, so the heard frequency matches option {answer}."
        )

    if has_all(blob, tight, ["oscilloscope", "y-gain"]) and contains(blob, tight, "amplitude"):
        return (
            f"The y-gain converts vertical screen height into voltage. Read the amplitude as half the peak-to-peak height, then multiply "
            f"by the y-gain to obtain the amplitude. That gives option {answer}."
        )

    if has_all(blob, tight, ["horizontal distance on the screen", "oscilloscope"]) or has_all(blob, tight, ["cro", "time-base"]):
        return (
            f"On a CRO, the horizontal scale is time because it is set by the time-base. Read the time for one cycle to get the period T, "
            f"then use f = 1 / T. That leads to option {answer}."
        )

    if has_all(blob, tight, ["miniature loudspeaker", "falls vertically", "frequency"]) and contains(blob, tight, "256 hz"):
        distance = first_number(blob, [r"fallen a distance of ([0-9.]+)\s*m"], 10.0)
        freq = first_number(blob, [r"frequency ([0-9.]+)\s*hz"], 256.0)
        wave_speed = first_number(blob, [r"speed of ([0-9.]+)\s*m"], 330.0)
        source_speed = math.sqrt(2 * 9.81 * distance)
        observed = freq * wave_speed / (wave_speed + source_speed)
        return (
            f"After falling {format_sig(distance)} m, the source speed is v = sqrt(2gs) ≈ {format_sig(source_speed)} m s^-1. The "
            f"speaker is moving away from the observer, so f' = fv / (v + vs) ≈ {format_sig(observed)} Hz, which matches option {answer}."
        )

    if has_all(blob, tight, ["guitar string is plucked", "air"]):
        return (
            f"The string vibrates perpendicular to the direction the wave travels, so the wave on the string is transverse. Sound in air "
            f"is made of compressions and rarefactions, so it is longitudinal. That is option {answer}."
        )

    if has_all(blob, tight, ["which row correctly identifies the properties of all electromagnetic waves"]):
        return (
            f"All electromagnetic waves are transverse, and all travel at the same speed in free space. The row that states both of "
            f"those properties is option {answer}."
        )

    if has_all(blob, tight, ["polarising filter", "45"]) or has_all(blob, tight, ["polarizing filter", "45"]):
        return (
            f"Use Malus' law at each filter: transmitted intensity is multiplied by cos^2(theta). The extra 45 degree filter reduces the "
            f"intensity in two stages, so the final fraction matches option {answer}."
        )

    if has_all(blob, tight, ["force on one side of the plate", "beneath the surface"]):
        force = first_number(blob, [r"pressure of the liquid is ([0-9.]+)\s*n", r"force .* is ([0-9.]+)\s*n"], 290.0)
        area = first_number(blob, [r"area ([0-9.]+)\s*m"], 0.036)
        density = first_number(blob, [r"density ([0-9.]+)\s*kg"], 930.0)
        pressure = force / area
        depth = pressure / (density * 9.81)
        return (
            f"First find the liquid pressure using p = F / A: {format_sig(force)} / {format_sig(area)} ≈ {pressure:.2e} Pa. Then use "
            f"p = rho gh, so h ≈ {pressure:.2e} / ({format_sig(density)} × 9.81) ≈ {format_sig(depth)} m. That gives option {answer}."
        )

    if has_all(blob, tight, ["elastic limit", "wire is stretched"]) or contains(blob, tight, "elastic limit"):
        return (
            f"The elastic limit is the point beyond which the material does not return fully to its original length when the force is "
            f"removed. So the correct statement is the one describing permanent, plastic deformation after this point, which is option {answer}."
        )

    if has_all(blob, tight, ["variation of l with f", "elastic potential energy"]) or contains(tight, tight, "variationoflwithf"):
        return (
            f"Elastic potential energy is the area under a force-extension graph, not the force-length graph. Read the extension at the "
            f"stated force, then use E = 1/2 Fx. This gives option {answer}."
        )

    if has_all(blob, tight, ["young modulus", "stress", "strain"]):
        return (
            f"Use stress = force / area and strain = extension / original length. Young modulus is stress / strain, so substitute the "
            f"given values step by step and compare with the options to obtain option {answer}."
        )

    if has_all(blob, tight, ["useful output power", "efficiency of the motor is"]):
        input_power = first_number(blob, [r"uses ([0-9.]+)\s*kw"], 1.7)
        efficiency = first_number(blob, [r"efficiency of the motor is ([0-9.]+)%"], 53.0)
        output_power = input_power * efficiency / 100
        return (
            f"Efficiency = useful output power / input power, so useful output power = eta P_in = {format_sig(efficiency)}% × "
            f"{format_sig(input_power)} kW ≈ {format_sig(output_power)} kW. That matches option {answer}."
        )

    if has_all(blob, tight, ["useful power output of the motor", "constant speed"]):
        return (
            f"At constant speed, useful power is the rate of gain of gravitational potential energy. Use P = mgv for the vertical motion, "
            f"then compare with the options to get option {answer}."
        )

    if has_all(blob, tight, ["what is the efficiency of the motor", "energy q is wasted"]):
        return (
            f"Efficiency is useful output divided by total input. If Q is wasted from an input E, then the useful output is E - Q, so "
            f"efficiency = (E - Q) / E. That corresponds to option {answer}."
        )

    if has_all(blob, tight, ["two satellites", "collide inelastically"]) or has_all(blob, tight, ["objects move off together", "inelastic"]):
        return (
            f"In an isolated system, total momentum is conserved during the collision, but some kinetic energy is usually transformed into "
            f"other forms in an inelastic collision. The row that shows momentum conserved and kinetic energy reduced is option {answer}."
        )

    if has_all(blob, tight, ["momentum 18 000", "mass 1200 kg"]) or has_all(blob, tight, ["has momentum", "what is the kinetic energy"]):
        momentum = first_number(blob, [r"momentum ([0-9 ]+) kg"], None)
        if momentum is None:
            momentum = 18000.0
        mass = first_number(blob, [r"mass ([0-9.]+)\s*kg"], 1200.0)
        kinetic_energy = momentum ** 2 / (2 * mass)
        return (
            f"Use p = mv together with E_k = 1/2 mv^2, which gives E_k = p^2 / (2m). Substituting the values gives "
            f"{kinetic_energy / 1000:.0f} kJ, so option {answer} is correct."
        )

    if has_all(blob, tight, ["train carriages", "join together"]) and contains(blob, tight, "kinetic energy lost"):
        return (
            f"First conserve momentum to find the common velocity after the collision. Then calculate the total kinetic energy before and "
            f"after, and subtract to find the loss. That leads to option {answer}."
        )

    if has_all(blob, tight, ["splits into two fragments", "mass m and the other has mass 2m"]) and contains(blob, tight, "total kinetic energy"):
        return (
            f"The firework starts from rest, so the two fragments have equal and opposite momenta. Use that momentum relation to write "
            f"both fragment speeds in terms of one variable, substitute into the total kinetic energy E, and solve. That gives option {answer}."
        )

    if has_all(blob, tight, ["explodes into two parts of equal mass", "one of which is then stationary"]):
        return (
            f"Momentum is conserved, so if one half stops, the other half must carry all the original momentum. Its speed therefore doubles, "
            f"and substituting into E_k = 1/2 mv^2 gives the correct option {answer}."
        )

    if has_all(blob, tight, ["block l moves back along its original path", "average force"]):
        dt = first_number(blob, [r"time of ([0-9.]+)\s*s"], 0.084)
        force = (0.46 + 0.12) / dt
        return (
            f"Average force is change in momentum divided by time. Block L reverses direction, so its momentum change is "
            f"0.46 + 0.12 = 0.58 kg m s^-1, giving F = 0.58 / {format_sig(dt)} ≈ {format_sig(force)} N. That is option {answer}."
        )

    if has_all(blob, tight, ["momentum of the block", "resistive force of 5.0 n"]):
        return (
            f"The gradient of the momentum-time graph gives the resultant force. Because the resultant force is F - 5.0 N, add the "
            f"5.0 N resistive force back onto the graph gradient to find the applied force. That gives option {answer}."
        )

    if has_all(blob, tight, ["principle of conservation of momentum", "system"]):
        return (
            f"Momentum of a system is conserved only when the resultant external force on the system is zero. So the correct statement is "
            f"the one that includes the condition of no external force, which is option {answer}."
        )

    if has_all(blob, tight, ["component of the final momentum", "combined objects", "angle of 35"]):
        return (
            f"Momentum is conserved in each direction separately. So the component of final momentum in the original direction of P is just "
            f"the sum of the initial momentum components in that same direction. That gives option {answer}."
        )

    if has_all(blob, tight, ["not possible for the underlined object to be in equilibrium"]):
        return (
            f"An object in equilibrium has zero resultant force and so zero acceleration. Constant speed alone is not enough; if the "
            f"direction changes, there is still acceleration. That makes option {answer} the impossible equilibrium case."
        )

    if has_all(blob, tight, ["what is not a valid relationship", "power dissipated in the resistor is p"]):
        return (
            f"Use the standard resistor equations P = VI = I^2R = V^2 / R and W = Pt. Three expressions can be derived from those "
            f"relations directly and one cannot, so the invalid one is option {answer}."
        )

    if has_all(blob, tight, ["lamp p is rated", "lamp q is rated"]) and has_any(blob, tight, ["connected in series", "250 v power supply"]):
        return (
            f"Use the ratings to find each lamp resistance from R = V^2 / P. In series the current is the same through both lamps, so the "
            f"lamp with the larger resistance dissipates more power because P = I^2R. That gives option {answer}."
        )

    if has_all(blob, tight, ["resistance of the variable resistor", "internal resistance"]):
        return (
            f"As the variable resistor increases, the current in the circuit falls. The p.d. across the internal resistance is Ir, so it "
            f"decreases, while the p.d. across the external resistor increases so that the two still add to the emf. That matches option {answer}."
        )

    if has_all(blob, tight, ["kirchhoff's first law", "quantity that is conserved"]) or has_all(blob, tight, ["kirchhoff's first and second laws", "conservation"]):
        return (
            f"Kirchhoff's first law comes from conservation of charge at a junction, while Kirchhoff's second law comes from conservation "
            f"of energy around a loop. The row that states those correctly is option {answer}."
        )

    if has_all(blob, tight, ["same useful output power", "filament lamps have an efficiency"]):
        return (
            f"For the same useful output, input power is inversely proportional to efficiency. So compare 1 / 0.40 with 1 / 0.05, or "
            f"equivalently take 0.05 / 0.40 for the requested ratio. That gives option {answer}."
        )

    if has_all(blob, tight, ["lamp x", "lamp y"]) and has_all(blob, tight, ["current in lamp x", "resistance is"]):
        return (
            f"Use P = I^2R for each lamp because current and resistance are given directly. Calculate the power of each lamp and then take "
            f"the requested ratio to obtain option {answer}."
        )

    if has_all(blob, tight, ["iron wire", "diameter", "resistance of the second wire"]):
        return (
            f"For the same material, R is proportional to L / A and the cross-sectional area A is proportional to diameter squared. Apply "
            f"those two proportionalities together to compare the two wires, and that gives option {answer}."
        )

    if has_all(blob, tight, ["component is represented by this circuit symbol"]) or contains(blob, tight, "circuit symbol"):
        return (
            f"Identify the component from its standard circuit symbol rather than from a calculation. Match the drawn symbol to the named "
            f"component in the options, which gives option {answer}."
        )

    if has_all(blob, tight, ["which equation can be obtained by applying kirchhoff's second law", "parallel"]):
        return (
            f"Kirchhoff's second law deals with potential differences around a loop. In a parallel circuit, each branch is connected "
            f"across the same two points, so each branch has the same p.d. as the supply. That is option {answer}."
        )

    if has_all(blob, tight, ["thermistor", "current i against the temperature"]):
        return (
            f"A thermistor with negative temperature coefficient has lower resistance at higher temperature. In the circuit, that means "
            f"the current increases as temperature rises, but not linearly. So the correct graph is option {answer}."
        )

    if has_any(blob, tight, ["light-dependent resistor", "thermistor", "potential divider", "output voltage", "vout"]):
        return (
            f"Start by deciding whether the sensor resistance rises or falls. Then apply the potential-divider idea to see whether the "
            f"output p.d. across the named component increases or decreases. That reasoning gives option {answer}."
        )

    if has_all(blob, tight, ["filament lamp", "semiconductor diode", "i-v"]):
        return (
            f"A filament lamp has a curved symmetric I-V graph because its resistance increases as it heats up. A diode conducts mainly "
            f"in one direction, so its graph is asymmetric. Matching those features gives option {answer}."
        )

    if has_all(blob, tight, ["which component has the i-v graph shown"]):
        return (
            f"Use the shape of the I-V graph to identify the component. Straight-line graphs show constant resistance, curved symmetric "
            f"graphs show heating effects, and one-way graphs indicate diode behaviour. That leads to option {answer}."
        )

    if has_all(blob, tight, ["momentum p", "until it hits the ground"]) and contains(blob, tight, "graph shows the variation"):
        return (
            f"With negligible air resistance, the falling object has constant acceleration g, so its velocity increases linearly with time. "
            f"Since p = mv and m is constant, momentum also increases linearly from zero. That matches option {answer}."
        )

    if has_all(blob, tight, ["momentum changes with time", "resultant force"]):
        return (
            f"Resultant force equals the rate of change of momentum, so use the gradient of the momentum-time graph. The steepest relevant "
            f"section gives the correct force, leading to option {answer}."
        )

    if topic == "Physical quantities and units / Units, measurements and vectors":
        if has_any(blob, tight, ["precision", "accurate", "precise"]):
            return (
                f"Precision is about how close repeated readings are to one another, while accuracy is about closeness to the true value. "
                f"Use those two definitions separately to test the statements, and that gives option {answer}."
            )
        if has_any(blob, tight, ["scalar", "vector", "component"]):
            return (
                f"Check which quantities need direction and which do not. If components are involved, resolve the vector into perpendicular "
                f"directions before comparing the options. That leads to option {answer}."
            )
        return (
            f"This is a units-and-measurements question. Simplify the units carefully, keep track of prefixes or uncertainties, and compare "
            f"the physical meaning of each option. That identifies option {answer}."
        )

    if topic == "Kinematics and acceleration / Motion in one and two dimensions":
        if has_any(blob, tight, ["velocity-time", "displacement-time", "distance-time", "acceleration-time", "graph"]):
            return (
                f"This is a motion-graph question. Use the correct graph rule: gradients give rates such as velocity or acceleration, and "
                f"areas under a velocity-time graph give displacement. That leads to option {answer}."
            )
        if has_any(blob, tight, ["projectile", "horizontal velocity", "building", "ground"]):
            return (
                f"This is projectile motion. Treat horizontal and vertical motion separately: horizontal velocity stays constant while the "
                f"vertical motion changes with acceleration g. Using that split gives option {answer}."
            )
        return (
            f"This is a kinematics question. Choose the constant-acceleration equation or motion definition that matches the given data, "
            f"substitute carefully, and that produces option {answer}."
        )

    if topic == "Forces and momentum / Dynamics and forces":
        if has_any(blob, tight, ["constant velocity", "stationary", "equilibrium"]):
            return (
                f"Zero acceleration means zero resultant force. So balance the forces shown in the question, or identify the case where "
                f"the forces cannot balance, to reach option {answer}."
            )
        return (
            f"This is a forces-and-momentum question. Draw the force picture mentally, resolve forces if necessary, and apply Newton's "
            f"laws or force balance to identify option {answer}."
        )

    if topic == "Forces and momentum / Forces, moments and equilibrium":
        return (
            f"In equilibrium, the total force is zero and the total clockwise moment equals the total anticlockwise moment. Use the more "
            f"useful of those two conditions for the diagram given, and that leads to option {answer}."
        )

    if topic == "Forces and momentum / Momentum and collisions":
        return (
            f"This is a momentum question. Choose a positive direction, conserve momentum during the interaction, and use force = Delta p / Delta t "
            f"if the question asks for an average force. That gives option {answer}."
        )

    if topic == "Matter and materials / Density, pressure and upthrust":
        return (
            f"This is a hydrostatic-pressure or density question. Decide first whether you need p = F / A, p = rho gh, density = m / V, "
            f"or the upthrust relation, then substitute the stated values carefully. That gives option {answer}."
        )

    if topic == "Matter and materials / Deformation of solids":
        return (
            f"This is an elasticity question. Use extension rather than total length, and then apply the relevant relation such as Hooke's "
            f"law, stress-strain ideas, or elastic energy. That leads to option {answer}."
        )

    if topic == "Work, energy and power / Energy and work":
        return (
            f"This is an energy question. Write down the energy balance first, then track how energy changes between kinetic, potential "
            f"and work done against forces. That gives option {answer}."
        )

    if topic == "Work, energy and power / Power and efficiency":
        return (
            f"This is a power-and-efficiency question. Decide whether the key idea is power = energy transferred per second or "
            f"efficiency = useful output / total input, then substitute carefully to obtain option {answer}."
        )

    if topic == "Electricity and circuits / Electrical quantities":
        return (
            f"This is an electrical-quantities question. Use the basic definitions directly, such as Q = It, V = W / Q and P = IV, and "
            f"match the calculation to the quantity being asked for. That gives option {answer}."
        )

    if topic == "Electricity and circuits / Resistance and circuit laws":
        if has_any(blob, tight, ["resistivity", "cross-sectional area", "cross sectional area", "diameter", "length 8.0 m", "iron wire"]):
            return (
                f"This circuit question is really about resistivity in a wire. Use R = rho L / A and remember that area depends on diameter "
                f"squared, then compare with the options to get option {answer}."
            )
        if has_any(blob, tight, ["internal resistance", "terminal potential difference", "emf", "battery", "cell"]):
            return (
                f"This is an internal-resistance question. Link the emf, terminal p.d. and the lost volts across the internal resistance, "
                f"then use the changing current or resistance to identify option {answer}."
            )
        if has_any(blob, tight, ["kirchhoff", "junction", "loop"]):
            return (
                f"This is a Kirchhoff-law question. At a junction, currents add because charge is conserved, and around a loop the p.d.s "
                f"sum because energy is conserved. That leads to option {answer}."
            )
        if has_any(blob, tight, ["lamp", "power", "efficiency"]):
            return (
                f"This circuit question is about electrical power in a lamp. Use P = IV, P = I^2R or P = V^2 / R, whichever matches the "
                f"given data best, and then compare with the options to obtain option {answer}."
            )
        if has_any(blob, tight, ["circuit symbol", "microphone", "loudspeaker", "buzzer", "electric bell"]):
            return (
                f"This is a component-symbol question. Match the standard circuit symbol directly to the correct named device, which gives "
                f"option {answer}."
            )
        return (
            f"This is a circuit-law question. Decide first which quantities are the same in series or parallel, then use Ohm's law, "
            f"resistor combinations, resistivity or Kirchhoff's laws as needed. That leads to option {answer}."
        )

    if topic == "Electricity and circuits / Practical circuits and sensors":
        return (
            f"This is a sensor-circuit question. Work out how the sensor resistance changes, then follow the effect through the circuit or "
            f"potential divider to identify the correct output behaviour. That gives option {answer}."
        )

    if topic == "Waves / General wave properties":
        if has_any(blob, tight, ["progressive wave", "transfer energy", "transverse wave", "longitudinal wave"]):
            return (
                f"This is a basic wave-properties question. Focus on what all progressive waves do, or on the distinction between transverse "
                f"and longitudinal motion, and that leads to option {answer}."
            )
        if has_any(blob, tight, ["oscilloscope", "cro", "time-base", "y-gain"]):
            return (
                f"This waves question is using an oscilloscope trace. Read time from the time-base, read voltage from the y-gain, and then "
                f"use the wave graph correctly to obtain option {answer}."
            )
        if has_any(blob, tight, ["towards a man", "approaches a stationary observer", "doppler", "horn emits", "jet aircraft"]):
            return (
                f"This is a Doppler-effect question. Decide whether the source is moving towards or away from the observer, then use that "
                f"to work out whether the observed frequency rises or falls, or calculate it directly. That gives option {answer}."
            )
        if has_any(blob, tight, ["in phase", "loudspeakers", "wavefronts", "path difference"]):
            return (
                f"This is a sound-interference question. Use the path difference between the two waves: constructive interference occurs for "
                f"whole wavelengths and destructive interference for half-odd multiples. That leads to option {answer}."
            )
        return (
            f"This is a waves question. Use the relevant wave idea directly, such as v = f lambda, wave type, Doppler effect, or the CRO "
            f"graph rules, and compare the result with the options. That gives option {answer}."
        )

    if topic == "Waves / Electromagnetic waves":
        return (
            f"This is an electromagnetic-wave question. Focus on properties such as being transverse, travelling at c in vacuum, position "
            f"in the spectrum, or polarisation, and that leads to option {answer}."
        )

    if topic == "Waves / Superposition and stationary waves":
        if has_any(blob, tight, ["double slit", "young", "path difference"]):
            return (
                f"This is a double-slit interference question. Bright fringes occur when the path difference is n lambda and dark fringes "
                f"occur for half-odd multiples, so use that condition to identify option {answer}."
            )
        if has_any(blob, tight, ["diffraction grating", "grating", "sin theta"]):
            return (
                f"This is a diffraction-grating question. Use the grating equation together with the order number and angle given, then "
                f"compare with the options to obtain option {answer}."
            )
        if has_any(blob, tight, ["stationary wave", "standing wave", "node", "antinode", "air column"]):
            return (
                f"This is a stationary-wave question. Adjacent nodes are half a wavelength apart, and a node to the next antinode is a "
                f"quarter wavelength. Use that spacing to find the required quantity and reach option {answer}."
            )
        if has_any(blob, tight, ["diffraction", "single slit"]):
            return (
                f"This is a diffraction question. The spreading depends on the wavelength compared with the gap size, so use that "
                f"relationship to decide which option is correct. That gives option {answer}."
            )
        return (
            f"This is a superposition question. Think in terms of path difference, interference conditions, or the spacing of nodes and "
            f"antinodes in a stationary wave. That identifies option {answer}."
        )

    if topic == "Atomic and particle physics / Radioactivity and nuclei":
        return (
            f"This is an atomic-physics question. Keep proton number, nucleon number and radiation properties separate, then apply the "
            f"relevant decay or nuclear-structure rule to obtain option {answer}."
        )

    if topic == "Atomic and particle physics / Fundamental particles":
        return (
            f"This is a particle-classification question. Quarks and leptons are fundamental, while hadrons such as protons, neutrons and "
            f"mesons are composite. Using that distinction gives option {answer}."
        )

    label = context_phrase(blob, tight, topic)
    return (
        f"This is a {label} question. Pick the physics principle that matches the quantities or statements given, apply it directly to the "
        f"question data, and that leads to option {answer}."
    )
