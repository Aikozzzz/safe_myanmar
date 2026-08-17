"""Create the small, non-critical ONNX intent-refinement demo artifact.

This is a project-owned demonstration model, not a production-trained safety
model. Tier 2 only runs after the deterministic classifier returns unknown and
the Android runtime still requires a confidence threshold and valid manifest.

Usage:
    python tools/create_demo_onnx_model.py

Requires the external ``onnx`` Python package for model generation only. The
generated model and manifest are written to the ignored ``ai_models`` folder.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

import onnx
from onnx import TensorProto, helper


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "ai_models"
MODEL_PATH = OUTPUT_DIR / "intent_classifier.onnx"
MANIFEST_PATH = OUTPUT_DIR / "intent_classifier.json"

LABELS = [
    "earthquake_guidance",
    "trapped_person",
    "first_aid",
    "fire",
    "flood",
    "safe_route",
    "find_shelter",
    "missing_person",
    "send_sos",
    "report_damage",
    "unknown",
]

TOKEN_LABELS = {
    "earthquake": "earthquake_guidance",
    "earthquakes": "earthquake_guidance",
    "quake": "earthquake_guidance",
    "shaking": "earthquake_guidance",
    "trapped": "trapped_person",
    "buried": "trapped_person",
    "rubble": "trapped_person",
    "injury": "first_aid",
    "injured": "first_aid",
    "wound": "first_aid",
    "bleeding": "first_aid",
    "fire": "fire",
    "smoke": "fire",
    "flood": "flood",
    "flooding": "flood",
    "water": "flood",
    "route": "safe_route",
    "road": "safe_route",
    "shelter": "find_shelter",
    "evacuate": "find_shelter",
    "missing": "missing_person",
    "lost": "missing_person",
    "sos": "send_sos",
    "help": "send_sos",
    "damage": "report_damage",
    "destroyed": "report_damage",
    "collapsed": "report_damage",
}

VOCABULARY = list(TOKEN_LABELS)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    label_index = {label: index for index, label in enumerate(LABELS)}
    width = len(VOCABULARY)
    height = len(LABELS)

    weights = [0.0] * (width * height)
    for token_index, token in enumerate(VOCABULARY):
        weights[token_index * height + label_index[TOKEN_LABELS[token]]] = 8.0

    bias = [0.0] * height
    bias[label_index["unknown"]] = 4.0

    graph = helper.make_graph(
        [
            helper.make_node("MatMul", ["input", "weights"], ["logits"]),
            helper.make_node("Add", ["logits", "bias"], ["biased_logits"]),
            helper.make_node("Softmax", ["biased_logits"], ["output"], axis=1),
        ],
        "SafeMyanmarDemoIntentClassifier",
        [helper.make_tensor_value_info("input", TensorProto.FLOAT, [1, width])],
        [helper.make_tensor_value_info("output", TensorProto.FLOAT, [1, height])],
        initializer=[
            helper.make_tensor("weights", TensorProto.FLOAT, [width, height], weights),
            helper.make_tensor("bias", TensorProto.FLOAT, [height], bias),
        ],
    )
    model = helper.make_model(
        graph,
        producer_name="SafeMyanmar",
        opset_imports=[helper.make_opsetid("", 13)],
    )
    model.ir_version = 8
    onnx.checker.check_model(model)
    onnx.save(model, MODEL_PATH)

    checksum = hashlib.sha256(MODEL_PATH.read_bytes()).hexdigest()
    MANIFEST_PATH.write_text(
        json.dumps(
            {
                "schemaVersion": 1,
                "modelVersion": "safemyanmar-demo-intent-v1",
                "sha256": checksum,
                "featureContract": "normalized_bag_of_words_v1",
                "outputContract": "probabilities_v1",
                "inputName": "input",
                "outputName": "output",
                "vocabulary": VOCABULARY,
                "labels": LABELS,
                "executionProvider": "cpu",
                "acceleratorValidated": False,
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {MODEL_PATH} ({MODEL_PATH.stat().st_size} bytes)")
    print(f"Wrote {MANIFEST_PATH}")
    print(f"SHA-256: {checksum}")


if __name__ == "__main__":
    main()
