# Design

## Current State
- `OnboardingWelcomePage` still advertises heart-rate based emotional measurement.
- `ContentView` and `OnboardingView` still include `OnboardingHealthPage`.
- `OnboardingViewModel` still imports HealthKit and exposes a heart-rate permission request.

## Approach
- Replace the heart-rate row with a How-card sharing message.
- Make the AirPods motion page the final onboarding step.
- Delete the HealthKit onboarding page and remove HealthKit authorization code from the onboarding view model.

