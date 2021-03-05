# Solving Bee

App to help with solving the New York Times Spelling Bee puzzle.

## Screenshots

| Splash Screen | Scanning | Word List | Word |
| - | - | - | - |
| ![Splash Screeen](Docs/Splash%20Screenshot.png) | ![Scanning](Docs/Scanning%20Screenshot.png) | ![Word List](Docs/Word%20List%20Screenshot.png) | ![Word](Docs/Word%20Screenshot.png) |

See also [this video](https://raw.githubusercontent.com/mihaip/solving-bee/main/Docs/Demo.mp4) for a walkthrough of the app.

## Training Data

A CoreML model is used to detect Spelling Bee boards via the camera. The model is trained over 1000 iterations with Create ML using the annotated images in the "Training Data" and "Testing Data" directories.

The images were annotated with [RectLabel](https://rectlabel.com/).

## Dictionary Data

Spelling Bee uses a proprietary dictionary that does not include proper nouns, some slang or some obscure domain-specific words. To approximate it, the 1/3 million most frequent words from the [Google Web Trillion Word Corpus](https://norvig.com/ngrams/) are used, with some filtering. This will end up with some proper nouns, so there's no guarantee that all preseted words are acceptable as solutions.

If you're interested in getting comprehensive solutions to Spelling Bee, see [this solver](https://www.shunn.net/bee/).
