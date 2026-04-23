#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path

from pypdf import PdfReader
from rapidocr_onnxruntime import RapidOCR

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from explanation_engine import explanation_for
from reclassify_topics import QUESTION_DATA_PATH, TOPIC_ORDER, SUBTOPIC_ORDER, classify_topic, image_path


YEAR_FOLDERS = {
    "2022": Path("/Users/yulinfeng/Documents/物理教学/Tests/2022Alevel Past Papers"),
    "2023": Path("/Users/yulinfeng/Documents/物理教学/Tests/2023Alevel past papers "),
    "2024": Path("/Users/yulinfeng/Documents/物理教学/Tests/2024Alevelpast papers"),
    "2025": Path("/Users/yulinfeng/Documents/物理教学/Tests/2025 Alelvel papers"),
}

SEASON_CODES = {
    "Feb": "m",
    "May": "s",
    "Nov": "w",
}


def question_number(question_id: str) -> int:
    return int(question_id.split("Q", 1)[1])


def prefix_from_id(question_id: str) -> str:
    return question_id.split("Q", 1)[0]


def season_from_prefix(prefix: str) -> str:
    if "Feb" in prefix:
        return "Feb"
    if "May" in prefix:
        return "May"
    if "Nov" in prefix:
        return "Nov"
    raise ValueError(f"Cannot determine season from prefix {prefix}")


def paper_from_prefix(prefix: str) -> str:
    match = re.search(r"(\d{2})$", prefix)
    if not match:
        raise ValueError(f"Cannot determine paper number from prefix {prefix}")
    return match.group(1)


def mark_scheme_path(prefix: str) -> Path:
    year = prefix[:4]
    folder = YEAR_FOLDERS[year]
    season = season_from_prefix(prefix)
    paper = paper_from_prefix(prefix)
    year_suffix = year[-2:]
    season_code = SEASON_CODES[season]
    pattern = f"9702_{season_code}{year_suffix}_ms_{paper}*.pdf"
    matches = sorted(folder.glob(pattern))
    if not matches:
        raise FileNotFoundError(f"No mark scheme found for {prefix} using {pattern}")
    return matches[0]


def extract_answers(pdf_path: Path) -> dict[int, str]:
    reader = PdfReader(str(pdf_path))
    text = "\n".join((page.extract_text() or "") for page in reader.pages)
    pairs = re.findall(r"\b([1-9]|[1-3][0-9]|40)\s+([ABCD])\s+1\b", text)
    ordered = sorted((int(index), letter) for index, letter in pairs)
    if len(ordered) != 40:
        raise ValueError(f"Expected 40 answers in {pdf_path}, found {len(ordered)}")
    return {index: letter for index, letter in ordered}


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


def main() -> None:
    parser = argparse.ArgumentParser(description="Regenerate QuestionData explanations and verify answers.")
    parser.add_argument(
        "--keep-topics",
        action="store_true",
        help="Keep the current topic strings instead of reclassifying from OCR text.",
    )
    parser.add_argument(
        "--no-sort",
        action="store_true",
        help="Preserve the current JSON order instead of sorting by topic/year/id.",
    )
    args = parser.parse_args()

    questions = json.loads(QUESTION_DATA_PATH.read_text())
    ocr = RapidOCR()

    prefixes = sorted({prefix_from_id(question["id"]) for question in questions})
    answer_lookup = {prefix: extract_answers(mark_scheme_path(prefix)) for prefix in prefixes}

    answer_changes = []
    topic_changes = []
    explanation_changes = 0
    topic_counter = Counter()

    for index, question in enumerate(questions, start=1):
        prefix = prefix_from_id(question["id"])
        qnum = question_number(question["id"])
        official_answer = answer_lookup[prefix][qnum]

        path = image_path(question["imageName"])
        if not path.exists():
            raise FileNotFoundError(f"Missing image for {question['id']}: {path}")

        result, _ = ocr(str(path))
        text = " ".join(item[1] for item in (result or []))

        if question["answer"] != official_answer:
            answer_changes.append((question["id"], question["answer"], official_answer))
            question["answer"] = official_answer

        detected_topic = classify_topic(question, text)
        if not args.keep_topics and question["topic"] != detected_topic:
            topic_changes.append((question["id"], question["topic"], detected_topic))
            question["topic"] = detected_topic

        explanation_topic = question["topic"] if args.keep_topics else detected_topic
        new_explanation = explanation_for(text, explanation_topic, question["answer"])
        if question["explanation"] != new_explanation:
            explanation_changes += 1
            question["explanation"] = new_explanation

        topic_counter[question["topic"]] += 1

        if index % 50 == 0:
            print(f"processed {index}/{len(questions)}")

    if not args.no_sort:
        questions.sort(key=sort_key)

    QUESTION_DATA_PATH.write_text(json.dumps(questions, ensure_ascii=False, indent=3) + "\n")

    print(f"Updated {QUESTION_DATA_PATH}")
    print(f"Answer changes: {len(answer_changes)}")
    print(f"Topic changes: {len(topic_changes)}")
    print(f"Explanation changes: {explanation_changes}")
    if answer_changes:
        print("Answer changes sample:")
        for item in answer_changes[:10]:
            print(item)
    if topic_changes:
        print("Topic changes sample:")
        for item in topic_changes[:10]:
            print(item)
    print("Top topic counts:")
    for topic, count in topic_counter.most_common():
        print(count, topic)


if __name__ == "__main__":
    main()
