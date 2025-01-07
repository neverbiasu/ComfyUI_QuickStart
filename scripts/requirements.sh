#!/bin/bash

cd ComfyUI

pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu124

pip install -r requirements.txt
