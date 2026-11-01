# Deen Launch Artwork

Regenerate the 1x, 2x and 3x mark images with `swift ios/generate_splash.swift`
from the repository root. The same script creates the matching Flutter dome
at `assets/images/deen_dome.png`. `LaunchScreen.storyboard` supplies the
emerald background and Deen wordmark. `Main.storyboard` uses the same
background to prevent a white frame before Flutter's first paint.
