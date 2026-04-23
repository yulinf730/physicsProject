#!/usr/bin/env python3
import json
import re
import sys
from pathlib import Path

from pypdf import PdfReader
from rapidocr_onnxruntime import RapidOCR

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from reclassify_topics import TOPIC_ORDER, SUBTOPIC_ORDER, classify_topic, normalize  # noqa: E402


REPO_ROOT = SCRIPT_DIR.parent
QUESTION_DATA_PATH = REPO_ROOT / "physicsProject" / "QuestionData.json"
ASSET_ROOT = REPO_ROOT / "physicsProject" / "Assets.xcassets"

PAPERS = [
    {
        "prefix": "2023Feb12",
        "year": "2023 Feb/March Paper 12",
        "mark_scheme": "/Users/yulinfeng/Documents/物理教学/Tests/2023Alevel past papers /9702_m23_ms_12.pdf",
    },
    {
        "prefix": "2023May11",
        "year": "2023 May/June Paper 11",
        "mark_scheme": "/Users/yulinfeng/Documents/物理教学/Tests/2023Alevel past papers /9702_s23_ms_11.pdf",
    },
    {
        "prefix": "2023May12",
        "year": "2023 May/June Paper 12",
        "mark_scheme": "/Users/yulinfeng/Documents/物理教学/Tests/2023Alevel past papers /9702_s23_ms_12.pdf",
    },
    {
        "prefix": "2023May13",
        "year": "2023 May/June Paper 13",
        "mark_scheme": "/Users/yulinfeng/Documents/物理教学/Tests/2023Alevel past papers /9702_s23_ms_13.pdf",
    },
    {
        "prefix": "2023Nov11",
        "year": "2023 Oct/Nov Paper 11",
        "mark_scheme": "/Users/yulinfeng/Documents/物理教学/Tests/2023Alevel past papers /9702_w23_ms_11.pdf",
    },
    {
        "prefix": "2023Nov12",
        "year": "2023 Oct/Nov Paper 12",
        "mark_scheme": "/Users/yulinfeng/Documents/物理教学/Tests/2023Alevel past papers /9702_w23_ms_12.pdf",
    },
    {
        "prefix": "2023Nov13",
        "year": "2023 Oct/Nov Paper 13",
        "mark_scheme": "/Users/yulinfeng/Documents/物理教学/Tests/2023Alevel past papers /9702_w23_ms_13.pdf",
    },
]


def extract_answer_string(pdf_path: str) -> str:
    reader = PdfReader(pdf_path)
    text = "\n".join((page.extract_text() or "") for page in reader.pages)
    pairs = re.findall(r"\b([1-9]|[1-3][0-9]|40)\s+([ABCD])\s+1\b", text)
    ordered = sorted((int(index), letter) for index, letter in pairs)
    if len(ordered) != 40:
        raise ValueError(f"Expected 40 answers in {pdf_path}, found {len(ordered)}")
    return "".join(letter for _, letter in ordered)


def image_path(image_name: str) -> Path:
    folder = image_name.rsplit("Q", 1)[0]
    return ASSET_ROOT / folder / f"{image_name}.imageset" / f"{image_name}.png"


def has_any(text: str, phrases) -> bool:
    return any(phrase in text for phrase in phrases)


def explanation_for(text: str, topic: str, answer: str) -> str:
    blob = normalize(text)

    if "jupiter" in blob and "radio wave" in blob:
        return f"The pulse time is for the out-and-back journey, so one-way distance = ct / 2 = 3.00 × 10^8 × 3960 / 2 = 5.94 × 10^11 m = 5.94 × 10^8 km, so the correct option is {answer}."

    if has_any(blob, ["horizontal distance on the screen", "horizontal distance on thescreen"]) and has_any(blob, ["oscilloscope", "cathode-ray oscilloscope", "cathode ray oscilloscope", "time base", "time-base"]):
        return f"The horizontal scale on a CRO is set by the time-base, so a horizontal measurement gives the period and hence the frequency of the sound wave. That makes option {answer} correct."

    if "momentum of a motorcycle changes with time" in blob or ("momentum" in blob and "time" in blob and "resultant force" in blob):
        return f"Resultant force is the rate of change of momentum, so use the gradient of the momentum-time graph to identify option {answer}."

    if "useful power output of the motor" in blob and "constant speed" in blob:
        return f"At constant speed, useful power is the gain in gravitational potential energy per second, so use P = mgv to obtain option {answer}."

    if "what is the efficiency of the motor" in blob and "energy q is wasted" in blob:
        return f"Efficiency = useful energy output / total energy input = (E - Q) / E, so the correct option is {answer}."

    if "which row correctly identifies the properties of all electromagnetic waves" in blob:
        return f"All electromagnetic waves are transverse and all travel at the same speed in free space, so option {answer} is correct."

    if "elastic limit" in blob:
        return f"Up to the elastic limit, the material returns to its original length when the force is removed. Beyond it, permanent deformation can occur, so option {answer} is correct."

    if "filament lamp" in blob and "semiconductor diode" in blob and "i-v" in blob:
        return f"A filament lamp has a curved symmetric I-V graph because its resistance increases with temperature, while a diode conducts mainly in one direction, giving option {answer}."

    if "which equation can be obtained by applying kirchhoff's second law" in blob and "parallel" in blob:
        return f"Kirchhoff's second law is about potential differences around a loop. In a parallel circuit, each branch has the same potential difference as the supply, so option {answer} is correct."

    if "which component has the i-v graph shown" in blob:
        return f"Match the shape of the I-V graph to the known characteristic of the component, then choose option {answer}."

    if "thermistor" in blob and "current i against the temperature" in blob:
        return f"For a thermistor with negative temperature coefficient, the resistance decreases as temperature rises. With a fixed cell and series resistor, the current therefore increases in a non-linear way, giving option {answer}."

    if "light-dependent resistor" in blob or "thermistor" in blob or "potential divider" in blob:
        return f"Use the potential-divider idea together with how the sensor resistance changes to justify option {answer}."

    if topic == "Physical quantities and units / Units, measurements and vectors":
        if "precision" in blob or "accuracy" in blob:
            return f"Precision is about how closely repeated values agree, while accuracy is about closeness to the true value, so option {answer} is correct."
        if has_any(blob, ["scalar", "vector", "component"]):
            return f"Use the distinction between scalar and vector quantities, or resolve the vector components as needed, to obtain option {answer}."
        return f"Use the correct SI unit, prefix, uncertainty rule or vector definition to identify option {answer}."

    if topic == "Kinematics and acceleration / Motion in one and two dimensions":
        if has_any(blob, ["velocity-time", "displacement-time", "distance-time", "area under", "gradient"]):
            return f"Use the gradient or area of the motion graph as appropriate to determine the correct answer, which is option {answer}."
        if "projectile" in blob:
            return f"Treat the horizontal and vertical components independently when analysing the projectile, which leads to option {answer}."
        return f"Use the equations of motion for constant acceleration to determine option {answer}."

    if topic == "Forces and momentum / Dynamics and forces":
        return f"Apply Newton's laws, force balance and the relevant force definitions to identify option {answer}."

    if topic == "Forces and momentum / Forces, moments and equilibrium":
        return f"Use the moment or torque relation, or the vector condition for equilibrium, to show that option {answer} is correct."

    if topic == "Forces and momentum / Momentum and collisions":
        return f"Apply conservation of momentum, or use force as the rate of change of momentum, to obtain option {answer}."

    if topic == "Matter and materials / Density, pressure and upthrust":
        return f"Use the relevant density, pressure, hydrostatic-pressure or upthrust relation to justify option {answer}."

    if topic == "Matter and materials / Deformation of solids":
        if has_any(blob, ["young modulus", "stress", "strain"]):
            return f"Use the definition of stress, strain and Young modulus for the material to obtain option {answer}."
        return f"Apply Hooke's law, the spring constant relation or elastic potential energy as needed to identify option {answer}."

    if topic == "Work, energy and power / Energy and work":
        return f"Use work done and conservation of energy, including kinetic and potential energy changes where needed, to obtain option {answer}."

    if topic == "Work, energy and power / Power and efficiency":
        return f"Use power as energy transferred per unit time, or efficiency as useful output divided by total input, to identify option {answer}."

    if topic == "Electricity and circuits / Electrical quantities":
        return f"Use the relevant electrical relation such as Q = It, V = W / Q or P = IV to justify option {answer}."

    if topic == "Electricity and circuits / Resistance and circuit laws":
        if "i-v" in blob or "current-voltage" in blob:
            return f"Match the I-V characteristic or use the resistance law involved to show that option {answer} is correct."
        return f"Apply V = IR, resistivity, Kirchhoff's laws, series/parallel combinations or internal resistance as needed to obtain option {answer}."

    if topic == "Electricity and circuits / Practical circuits and sensors":
        return f"Use the practical circuit arrangement, especially the behaviour of the LDR, thermistor or potential divider, to identify option {answer}."

    if topic == "Waves / General wave properties":
        if "doppler" in blob:
            return f"Use the Doppler-effect relation for a moving source and stationary observer to obtain option {answer}."
        return f"Use the wave relation, phase difference, diffraction behaviour or other general wave property needed here to identify option {answer}."

    if topic == "Waves / Electromagnetic waves":
        return f"Use the key properties of electromagnetic waves, including their common speed in free space and the electromagnetic spectrum, to justify option {answer}."

    if topic == "Waves / Superposition and stationary waves":
        return f"Apply the principle of superposition together with interference, diffraction or stationary-wave ideas to obtain option {answer}."

    if topic == "Atomic and particle physics / Radioactivity and nuclei":
        return f"Use the structure of atoms and nuclei, or the properties of radioactive decay and radiation, to identify option {answer}."

    if topic == "Atomic and particle physics / Fundamental particles":
        return f"Quarks and leptons are fundamental, while hadrons such as protons, neutrons and mesons are composite, so option {answer} is correct."

    return f"Apply the key idea in this question carefully to determine that option {answer} is correct."


def sort_key(question):
    parts = question["topic"].split(" / ")
    major = parts[0]
    sub = parts[1] if len(parts) > 1 else ""
    return (
        TOPIC_ORDER.index(major) if major in TOPIC_ORDER else len(TOPIC_ORDER),
        SUBTOPIC_ORDER.index(sub) if sub in SUBTOPIC_ORDER else len(SUBTOPIC_ORDER),
        question["year"],
        question["id"],
    )


def main():
    questions = json.loads(QUESTION_DATA_PATH.read_text())
    questions = [q for q in questions if not q["id"].startswith("2023")]

    ocr = RapidOCR()

    for paper in PAPERS:
        answers = extract_answer_string(paper["mark_scheme"])
        prefix = paper["prefix"]

        for index, answer in enumerate(answers, start=1):
            image_name = f"Alevel{prefix}Q{index}"
            path = image_path(image_name)
            if not path.exists():
                raise FileNotFoundError(f"Missing asset for {image_name}")

            result, _ = ocr(str(path))
            text = " ".join(item[1] for item in (result or []))

            base_question = {
                "id": f"{prefix}Q{index}",
                "topic": "",
                "year": paper["year"],
                "imageName": image_name,
                "options": ["A", "B", "C", "D"],
                "answer": answer,
                "explanation": "",
            }

            topic = classify_topic(base_question, text)
            base_question["topic"] = topic
            base_question["explanation"] = explanation_for(text, topic, answer)
            questions.append(base_question)

        print(f"added {prefix}")

    questions.sort(key=sort_key)
    QUESTION_DATA_PATH.write_text(json.dumps(questions, ensure_ascii=False, indent=3) + "\n")
    print(f"Updated {QUESTION_DATA_PATH}")


if __name__ == "__main__":
    main()
