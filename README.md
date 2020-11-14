# Solving Bee

App to help with solving the New York Times Spelling Bee puzzle.

## Training Data

A CoreML model is used to detect Spelling Bee boards via the camera. The model is trained over 1000 iterations with Create ML using the annotated images in the "Training Data" and "Testing Data" directories.

The images were annotated with [RectLabel](https://rectlabel.com/).
