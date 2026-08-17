# Optional AI Model Provisioning

## Default Behavior

SafeMyanmar bundles no ONNX, LiteRT-LM, or other model artifact. It contains no
model downloader, model registry credentials, remote AI API, or runtime update
service. The deterministic Dart classifier and approved Drift Guide content are
the default and remain available when every optional artifact is absent or
unusable.

Provisioning is an operator/development task outside the app. Before placing an
artifact on a device, verify that its source and license permit the intended
use, redistribution, and device deployment. Do not commit licensed model files,
credentials, or local provisioning output to this repository.

## Fixed Android Paths

The native bridge reads only these files under the application's private data
directory:

```text
filesDir/ai/intent_classifier.onnx
filesDir/ai/intent_classifier.json
filesDir/ai/gemma3-1b-it-int4.litertlm
filesDir/ai/gemma3-1b-it-int4.json
```

The model and its manifest must be regular files with the same canonical parent
directory. External/shared-storage paths are not supported. The app neither
copies nor downloads these files. A clean install normally has no optional AI
capability until an authorized provisioning process writes app-private files.

## Common Manifest Contract

`ModelArtifactValidator` accepts schema version 1 only. Both JSON manifests
require:

| Field | Contract |
|---|---|
| `schemaVersion` | Integer exactly `1` |
| `modelVersion` | 1-64 characters matching letters, digits, `.`, `_`, or `-` |
| `sha256` | Exactly 64 hexadecimal characters containing the SHA-256 of the adjacent model file |

The manifest is limited to 1,000,000 bytes. Validation computes the complete
model SHA-256 and compares it in constant-time form. Generate the checksum from
the exact licensed artifact being provisioned; this repository intentionally
provides no model hash.

## ONNX Intent Manifest

`intent_classifier.json` additionally requires:

| Field | Contract |
|---|---|
| `featureContract` | Exact value `normalized_bag_of_words_v1` |
| `outputContract` | Exact value `probabilities_v1` |
| `inputName` | 1-128 characters using letters, digits, `.`, `_`, `/`, or `-` |
| `outputName` | Same node-name contract as `inputName` |
| `vocabulary` | 1-16,384 unique lowercase strings, each at most 80 characters |
| `labels` | 2-128 unique strings using the `modelVersion` character contract |
| `executionProvider` | Optional `cpu`, `nnapi`, or `xnnpack`; defaults to `cpu` |
| `acceleratorValidated` | Optional boolean; defaults to `false` |

The model must expose exactly one float input shaped `[1, vocabulary length]`
(a dynamic first dimension is accepted) and one float output shaped
`[1, labels length]`. Output values must be finite probabilities in `[0, 1]`
whose sum is approximately 1. Unsupported labels are ignored by the Dart
assistant. A recognized optional result is used only after deterministic Tier 1
returns unknown and confidence is at least `0.75`.

Acceleration is used only when `acceleratorValidated=true` and the device
supports the requested provider; otherwise ONNX runs on CPU. Session creation
may fall back to CPU. Any validation or runtime failure returns to the
deterministic classifier.

## LiteRT-LM Manifest And Resources

`gemma3-1b-it-int4.json` additionally requires:

| Field | Contract |
|---|---|
| `modelId` | Exact value `gemma3-1b-it-int4.litertlm` |

The runtime supports `arm64-v8a` and `x86_64`, initializes LiteRT-LM with
`Backend.CPU()` only, and checks device resources before initialization. Tier 3 is unavailable when the
device reports low memory, total memory below 2.5 GiB, available memory below
1.25 GiB, or app-private free storage below the larger of 768 MiB and half the
model file size.

LiteRT-LM receives either the current verified English article or a bounded set
of approved offline disaster context, plus the user question. It may answer
general non-critical questions, with disaster and preparedness topics prioritized,
but must not invent live alerts, diagnoses, guaranteed-safe routes, rescue
dispatch, or unsupported emergency instructions. The blocking LiteRT-LM
`sendMessage` call runs on the native bridge's background dispatcher; failures
return to deterministic content. The asynchronous Flow overload is intentionally
avoided because the Android artifact currently has a coroutines callback ABI
mismatch.
Trapped-person, first-aid, SOS, and safer-route requests are blocked from Tier 3.
Its output is visibly secondary to the unchanged source-backed article.

## Provisioning Checklist

1. Obtain each model through an authorized channel and review its license and
   redistribution/device-use terms.
2. Validate model provenance and test the exact runtime, tensor, label, safety,
   ABI, memory, and storage contracts on target devices.
3. Compute SHA-256 from the final artifact and write it into its local schema-v1
   manifest. Do not use a placeholder or a hash from another build.
4. Place only the expected model/manifest pair in `filesDir/ai` using an
   authorized app-private provisioning process.
5. Confirm the in-app capability banner and deterministic fallback behavior.
6. Remove unsupported or expired artifacts through the same authorized process;
   the app has no lifecycle or download manager for them.

## SafeMyanmar Demo ONNX Artifact

For local development only, the repository includes a generator for a small
project-owned intent-refinement artifact:

```powershell
python -m pip install --target "$env:TEMP\safemyanmar-onnx" onnx==1.20.0
$env:PYTHONPATH = "$env:TEMP\safemyanmar-onnx"
python tools/create_demo_onnx_model.py
```

This writes `intent_classifier.onnx` and its checksum manifest into the ignored
`ai_models/` directory. It is a simple keyword-weighted demonstration model,
not a production-trained safety model. Tier 2 remains restricted to unknown
deterministic results and the existing confidence threshold. Replace it with
an authorized, evaluated model before any real deployment.

## Development Provisioning With A Debug Device

The application never accepts a model path from Flutter and never reads shared
storage. For an authorized debug device, install a debug build first, then use
the package ID from `mobile/android/app/build.gradle.kts`:

```powershell
Set-Location mobile
adb devices
adb shell run-as org.safemyanmar.mobile pwd
adb shell run-as org.safemyanmar.mobile mkdir -p files/ai
adb shell mkdir -p /data/local/tmp/safemyanmar-ai
adb push ..\ai_models\intent_classifier.onnx /data/local/tmp/safemyanmar-ai/
adb push ..\ai_models\intent_classifier.json /data/local/tmp/safemyanmar-ai/
adb push ..\ai_models\gemma3-1b-it-int4.litertlm /data/local/tmp/safemyanmar-ai/
adb push ..\ai_models\gemma3-1b-it-int4.json /data/local/tmp/safemyanmar-ai/
adb shell run-as org.safemyanmar.mobile cp /data/local/tmp/safemyanmar-ai/intent_classifier.onnx files/ai/intent_classifier.onnx
adb shell run-as org.safemyanmar.mobile cp /data/local/tmp/safemyanmar-ai/intent_classifier.json files/ai/intent_classifier.json
adb shell run-as org.safemyanmar.mobile cp /data/local/tmp/safemyanmar-ai/gemma3-1b-it-int4.litertlm files/ai/gemma3-1b-it-int4.litertlm
adb shell run-as org.safemyanmar.mobile cp /data/local/tmp/safemyanmar-ai/gemma3-1b-it-int4.json files/ai/gemma3-1b-it-int4.json
adb shell run-as org.safemyanmar.mobile ls -lh files/ai
adb shell am force-stop org.safemyanmar.mobile
```

Replace the package ID or model source path when they differ. These commands
require an authorized model artifact and manifest; no model files are included
in this repository.
