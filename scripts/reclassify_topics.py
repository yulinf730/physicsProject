#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path

from rapidocr_onnxruntime import RapidOCR

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from explanation_engine import compact, contains as engine_contains, has_any as engine_has_any, normalize


REPO_ROOT = Path(__file__).resolve().parents[1]
QUESTION_DATA_PATH = REPO_ROOT / "physicsProject" / "QuestionData.json"
ASSET_ROOT = REPO_ROOT / "physicsProject" / "Assets.xcassets"


TOPIC_ORDER = [
    "Physical quantities and units",
    "Kinematics and acceleration",
    "Forces and momentum",
    "Matter and materials",
    "Work, energy and power",
    "Electricity and circuits",
    "Waves",
    "Atomic and particle physics",
]

SUBTOPIC_ORDER = [
    "Units, measurements and vectors",
    "Motion in one and two dimensions",
    "Dynamics and forces",
    "Forces, moments and equilibrium",
    "Momentum and collisions",
    "Density, pressure and upthrust",
    "Deformation of solids",
    "Energy and work",
    "Power and efficiency",
    "Electrical quantities",
    "Resistance and circuit laws",
    "Practical circuits and sensors",
    "General wave properties",
    "Electromagnetic waves",
    "Superposition and stationary waves",
    "Radioactivity and nuclei",
    "Fundamental particles",
]


def load_questions():
    return json.loads(QUESTION_DATA_PATH.read_text())


def question_number(question_id: str) -> int:
    return int(question_id.split("Q", 1)[1])


def image_path(image_name: str) -> Path:
    folder = image_name.rsplit("Q", 1)[0]
    return ASSET_ROOT / folder / f"{image_name}.imageset" / f"{image_name}.png"


def has_any(text: str, phrases) -> bool:
    return engine_has_any(text, compact(text), phrases)


def contains(text: str, phrase: str) -> bool:
    return engine_contains(text, compact(text), phrase)


def classify_topic(question, text: str) -> str:
    qnum = question_number(question["id"])
    blob = normalize(text)

    overrides = {
        "2025May12Q5": "Waves / Electromagnetic waves",
        "2025May14Q23": "Waves / Electromagnetic waves",
    }
    if question["id"] in overrides:
        return overrides[question["id"]]

    if has_any(blob, [
        "electromagnetic waves",
        "radio wave",
        "microwave",
        "infrared",
        "ultraviolet",
        "x-ray",
        "x ray",
        "gamma-ray",
        "gamma ray",
        "visible",
        "human eye",
        "polarisation",
        "polarization",
        "polarised",
        "polarized",
        "malus",
        "jupiter",
    ]):
        return "Waves / Electromagnetic waves"

    if has_any(blob, [
        "double slit",
        "diffraction",
        "grating",
        "coherence",
        "interference",
        "superposition",
        "stationary wave",
        "standing wave",
        "node",
        "antinode",
        "air column",
        "young",
        "single slit",
    ]):
        return "Waves / Superposition and stationary waves"

    if has_any(blob, [
        "sound wave",
        "wave speed",
        "wavelength",
        "frequency",
        "time-base",
        "time base",
        "cathode-ray oscilloscope",
        "cathode ray oscilloscope",
        "oscilloscope",
        "period of the wave",
        "progressive wave",
        "transverse wave",
        "longitudinal wave",
        "phase difference",
        "intensity of the sound",
        "intensity of a sound",
        "ultrasound",
    ]):
        return "Waves / General wave properties"

    if has_any(blob, [
        "young modulus",
        "hooke",
        "elastic limit",
        "spring constant",
        "extension",
        "compression",
        "tensile force",
        "strain",
        "stress",
        "elastic potential energy",
        "wire is stretched",
        "limit of proportionality",
    ]):
        return "Matter and materials / Deformation of solids"

    if has_any(blob, [
        "speed",
        "velocity",
        "acceleration",
        "displacement",
        "projectile",
        "horizontal velocity",
        "top of a building",
        "hits the ground",
        "distance-time",
        "displacement-time",
        "velocity-time",
        "speed-time",
        "equations of motion",
        "free fall",
        "constant acceleration",
    ]):
        return "Kinematics and acceleration / Motion in one and two dimensions"

    if has_any(blob, [
        "resultant force",
        "air resistance",
        "frictionless surface",
        "constant velocity",
        "newton's second law",
        "newton's first law",
        "newton's third law",
        "mass and acceleration",
        "drag force",
        "terminal speed",
        "terminal velocity",
    ]):
        return "Forces and momentum / Dynamics and forces"

    if has_any(blob, [
        "thermistor",
        "light-dependent resistor",
        "ldr",
        "potential divider",
        "potentiometer",
        "galvanometer",
        "sensor",
        "output voltage",
        "vout",
    ]) and not has_any(blob, [
        "i-v",
        "current-voltage",
        "semiconductor diode",
        "filament lamp",
        "metallic conductor",
    ]):
        return "Electricity and circuits / Practical circuits and sensors"

    if has_any(blob, [
        "resistivity",
        "ohm's law",
        "ohms law",
        "kirchhoff",
        "internal resistance",
        "terminal potential difference",
        "terminal p.d.",
        "i-v",
        "current-voltage",
        "semiconductor diode",
        "filament lamp",
        "metallic conductor",
        "resistor",
        "resistors",
        "resistance of",
        "resistance r",
        "series circuit",
        "parallel circuit",
        "ammeter",
        "voltmeter",
        "cell",
        "battery",
        "cross-sectional area",
        "cross sectional area",
    ]) or (contains(blob, "wire") and has_any(blob, ["current", "potential difference", "resistivity", "circuit", "resistance"])):
        return "Electricity and circuits / Resistance and circuit laws"

    if has_any(blob, [
        "charge",
        "q = it",
        "electric current",
        "potential difference",
        "electric power",
        "electrical power",
        "power dissipated",
        "e.m.f",
        "emf",
        "current in the resistor",
        "current in a resistor",
    ]):
        return "Electricity and circuits / Electrical quantities"

    if has_any(blob, [
        "density",
        "pressure",
        "hydrostatic",
        "upthrust",
        "archimedes",
        "fluid",
        "liquid",
    ]):
        return "Matter and materials / Density, pressure and upthrust"

    if has_any(blob, [
        "momentum",
        "collision",
        "elastic collision",
        "inelastic",
        "explosion",
        "crash-landing",
        "crash landing",
        "relative speed of approach",
        "relative speed of separation",
    ]):
        return "Forces and momentum / Momentum and collisions"

    if has_any(blob, [
        "moment of a force",
        "torque",
        "couple",
        "centre of gravity",
        "center of gravity",
        "equilibrium",
        "coplanar",
        "components of vectors",
        "components of vector",
        "lines of action",
    ]):
        return "Forces and momentum / Forces, moments and equilibrium"

    if has_any(blob, [
        "power",
        "efficiency",
        "useful output",
        "useful power",
        "output power",
        "input power",
        "p = fv",
    ]) and has_any(blob, [
        "motor",
        "engine",
        "lift",
        "pump",
        "useful",
        "wasted",
    ]):
        return "Work, energy and power / Power and efficiency"

    if has_any(blob, [
        "kinetic energy",
        "gravitational potential energy",
        "potential energy",
        "work done",
        "energy transferred",
        "energy change",
    ]):
        return "Work, energy and power / Energy and work"

    if has_any(blob, [
        "unit",
        "units",
        "base quantity",
        "derived quantity",
        "percentage uncertainty",
        "uncertainty",
        "scalar",
        "vector",
        "physical quantity",
    ]):
        return "Physical quantities and units / Units, measurements and vectors"

    if 38 <= qnum <= 40:
        if has_any(blob, [
            "fundamental particle",
            "quark",
            "baryon",
            "meson",
            "lepton",
            "hadron",
            "neutrino",
            "antineutrino",
            "positron",
            "upquark",
            "downquark",
            "charmquark",
            "topquark",
            "bottomquark",
            "strangequark",
        ]):
            return "Atomic and particle physics / Fundamental particles"
        return "Atomic and particle physics / Radioactivity and nuclei"

    if 32 <= qnum <= 37:
        if has_any(blob, [
            "thermistor",
            "light-dependent resistor",
            "ldr",
            "potential divider",
            "potentiometer",
            "galvanometer",
            "sensor",
            "vout",
            "output voltage",
        ]) and not has_any(blob, [
            "i-v",
            "current-voltage",
            "semiconductor diode",
            "filament lamp",
            "metallic conductor",
        ]):
            return "Electricity and circuits / Practical circuits and sensors"
        if has_any(blob, [
            "resistance",
            "resistivity",
            "ohm's law",
            "ohms law",
            "i-v",
            "current-voltage",
            "series circuit",
            "parallel circuit",
            "kirchhoff",
            "e.m.f",
            "emf",
            "internal resistance",
            "terminal potential difference",
            "terminal p.d.",
            "resistor",
            "resistors",
            "cross-sectional area",
            "cross sectional area",
            "semiconductor diode",
            "filament lamp",
            "metallic conductor",
            "variable resistor",
            "ammeter reads zero",
        ]) or (contains(blob, "wire") and has_any(blob, ["current", "potential difference", "resistivity", "circuit", "resistance"])):
            return "Electricity and circuits / Resistance and circuit laws"
        if has_any(blob, [
            "charge",
            "electric current",
            "potential difference",
            "voltage",
            "power dissipated",
            "electrical power",
            "current in a resistor",
            "q = it",
        ]):
            return "Electricity and circuits / Electrical quantities"
        return "Electricity and circuits / Resistance and circuit laws"

    if 25 <= qnum <= 31:
        if has_any(blob, [
            "double slit",
            "diffraction",
            "grating",
            "coherence",
            "interference",
            "superposition",
            "stationary wave",
            "standing wave",
            "node",
            "antinode",
            "air column",
            "young",
            "single slit",
        ]):
            return "Waves / Superposition and stationary waves"
        if has_any(blob, [
            "electromagnetic",
            "radio wave",
            "microwave",
            "infrared",
            "ultraviolet",
            "x-ray",
            "x ray",
            "gamma-ray",
            "gamma ray",
            "visible",
            "human eye",
            "polarisation",
            "polarization",
            "polarised",
            "polarized",
            "malus",
            "jupiter",
        ]):
            return "Waves / Electromagnetic waves"
        return "Waves / General wave properties"

    if 8 <= qnum <= 24:
        if has_any(blob, [
            "young modulus",
            "hooke",
            "spring constant",
            "extension",
            "compression",
            "strain",
            "stress",
            "elastic potential energy",
            "wire is stretched",
            "limit of proportionality",
            "spring",
        ]):
            return "Matter and materials / Deformation of solids"
        if has_any(blob, [
            "density",
            "pressure",
            "hydrostatic",
            "upthrust",
            "archimedes",
            "fluid",
            "liquid",
            "ρg",
            "delta p",
        ]):
            return "Matter and materials / Density, pressure and upthrust"
        if has_any(blob, [
            "momentum",
            "collision",
            "elastic collision",
            "inelastic",
            "explosion",
            "crash-landing",
            "crash landing",
            "relative speed of approach",
            "relative speed of separation",
            "kg m s-1",
        ]):
            return "Forces and momentum / Momentum and collisions"
        if has_any(blob, [
            "moment of a force",
            "torque",
            "couple",
            "centre of gravity",
            "center of gravity",
            "equilibrium",
            "vector triangle",
            "coplanar",
            "components of vectors",
            "components of vector",
            "angle between the lines of action",
        ]):
            return "Forces and momentum / Forces, moments and equilibrium"
        if has_any(blob, [
            "power",
            "efficiency",
            "useful output",
            "useful power",
            "output power",
            "motor",
            "p = fv",
        ]):
            return "Work, energy and power / Power and efficiency"
        if has_any(blob, [
            "kinetic energy",
            "gravitational potential energy",
            "potential energy",
            "work done",
            "energy transferred",
            "energy change",
            "rebound",
            "slope",
        ]):
            return "Work, energy and power / Energy and work"
        return "Forces and momentum / Dynamics and forces"

    if 5 <= qnum <= 7:
        return "Kinematics and acceleration / Motion in one and two dimensions"

    if qnum <= 4:
        return "Physical quantities and units / Units, measurements and vectors"

    if has_any(blob, [
        "fundamental particle",
        "quark",
        "baryon",
        "meson",
        "lepton",
        "hadron",
        "neutrino",
        "antineutrino",
        "positron",
        "upquark",
        "downquark",
        "charmquark",
        "topquark",
        "bottomquark",
        "strangequark",
    ]):
        return "Atomic and particle physics / Fundamental particles"
    return "Atomic and particle physics / Radioactivity and nuclei"


def main():
    questions = load_questions()
    ocr = RapidOCR()

    for i, question in enumerate(questions, start=1):
        path = image_path(question["imageName"])
        if not path.exists():
            raise FileNotFoundError(f"Missing image for {question['id']}: {path}")

        result, _ = ocr(str(path))
        text = " ".join(item[1] for item in (result or []))
        question["topic"] = classify_topic(question, text)

        if i % 100 == 0:
            print(f"classified {i}/{len(questions)}")

    questions.sort(
        key=lambda q: (
            TOPIC_ORDER.index(q["topic"].split(" / ")[0]) if q["topic"].split(" / ")[0] in TOPIC_ORDER else len(TOPIC_ORDER),
            SUBTOPIC_ORDER.index(q["topic"].split(" / ")[1]) if " / " in q["topic"] and q["topic"].split(" / ")[1] in SUBTOPIC_ORDER else len(SUBTOPIC_ORDER),
            q["year"],
            q["id"],
        )
    )

    QUESTION_DATA_PATH.write_text(json.dumps(questions, ensure_ascii=False, indent=3) + "\n")
    print(f"Updated {QUESTION_DATA_PATH}")


if __name__ == "__main__":
    main()
