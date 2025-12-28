# How we got here
### The history of how we built this project

First we tried to build this project the old-fashioned way: by getting SpecKit and Gemini to generate code from specifications. But we quickly ran into limitations with that approach, as SpecKit and Gemini struggled to handle the complexity of a full macOS app with multiple components and services.
So we pivoted to a new approach: Building the baseline XPC service and SwiftUI app manually, then using SpecKit to help us fill in the gaps, generate boilerplate code, and assist with specific tasks like setting up ICMP pinging and menu bar integration.

This hybrid approach allowed us to leverage the strengths of both human developers and AI tools. We could rely on our own expertise to design the overall architecture and user experience, while using SpecKit to handle repetitive coding tasks and generate code snippets based on detailed specifications.

## Clarifications
### Session 2025-12-24
- Q: What is the required format for the timestamped response from the XPC service? → A: ISO 8601 String (e.g., `2025-12-24T18:30:00Z`)
- Q: Where in the user interface should the timestamped response from the XPC service be displayed? → A: In a new Text view below the button.
- Q: What is the expected behavior if the XPC service communication fails (e.g., service not running, connection lost)? → A: Display an error message in the UI.

## How to build the SwiftUI menu bar app with XPC service

### Creating an Xcode Project with an XPC Component
**Step 1: Set Up the macOS Application**
1. Open Xcode.
2. Select "macOS" and then "App."
3. Enter a product name (e.g., "DemoApp") and click "Next."
4. Choose a location to save your project and click "Create."

**Step 2: Add an XPC Service Target**
1. In the Xcode menu, click on File > New > Target.
2. Select XPC Service from the list.
3. Enter a product name for the service (e.g., "DemoService") and click "Finish."

**Step 3: Understand the Project Structure**
After creating the XPC service, your project will have a new folder for the service. This includes:
- **DemoServiceProtocol.swift**: Defines the API that the service will expose.
- **main.swift**: Contains the code to accept incoming connections.


## How to test the XPC service integration
We want to test the XPC service integration to ensure that the SwiftUI app can communicate with the XPC service correctly. We don't want to make a huge number of changes to the existing codebase, so we will create a simple test case that verifies the communication between the app and the service.

### Step 1: Define the Test Case

1. Our prompt to Gemini is as follows : 
> the first feature is a small MVP to implement the XPC service in the MacOS base project we've created in the NetworkReporter/ folder. You will use the smallest and most focused code changes to verfiy that the MacOS app is communicating with the XPC service and vice-versa. Tell me your plan before you implement.
2. Fix the build errors in the generated code.
> update the code so that when I press the button in the app, I get a timestamped response from the XPC client in ISO 8601 format (e.g., "2025-12-24T18:30:00Z"), displayed in a new Text view below the button. If the communication fails, an error message should be displayed in the UI. I want to be sure that what i'm seeing is a connection between the two apps and the interface is working.

## How to build the app using SpecKit and Gemini
1. First, we set up the SpecKit configuration to define the specifications for our XPC
service and SwiftUI app.
2. Next, we used Gemini to generate the initial codebase based on our specifications.
3. We then manually built the baseline XPC service and SwiftUI app, ensuring that the

For the implementation, we used the following prompt:
> Run the following build command: xcodebuild -scheme NetworkReporter -configuration Debug -workspace /Users/XYZ/Documents/Projects/SDD/network-report/NetworkReporter/NetworkReporter.xcodeproj/project.xcworkspace -destination platform\=macOS\,arch\=arm64 -allowProvisioningUpdates build. If the build fails, analyse the error output, identify the incorrect code in my files, and apply the fixes automatically, then re-issue the build command. You may only stop this loop when the application builds successfully.