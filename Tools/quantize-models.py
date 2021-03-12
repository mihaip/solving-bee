#!/usr/local/bin/python3

import coremltools.models
import coremltools.models.neural_network
import os.path

models_dir = os.path.join(os.path.dirname(__file__), "..", "Solving Bee", "Resources")
for model_name in ["LettersModel", "BoardModel"]:
    model_path = os.path.join(models_dir, f"{model_name}.mlmodel")
    model_fp32 = coremltools.models.MLModel(model_path)
    model_fp16 = coremltools.models.neural_network.quantization_utils.quantize_weights(model_fp32, nbits=16)
    model_fp16.save(model_path)
