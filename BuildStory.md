# How we got here
### The history of how we built this project

First we tried to build this project the old-fashioned way: by getting SpecKit and Gemini to generate code from specifications. But we quickly ran into limitations with that approach, as SpecKit and Gemini struggled to handle the complexity of a full macOS app with multiple components and services.
So we pivoted to a new approach: Building the baseline XPC service and SwiftUI app manually, then using SpecKit to help us fill in the gaps, generate boilerplate code, and assist with specific tasks like setting up ICMP pinging and menu bar integration.

This hybrid approach allowed us to leverage the strengths of both human developers and AI tools. We could rely on our own expertise to design the overall architecture and user experience, while using SpecKit to handle repetitive coding tasks and generate code snippets based on detailed specifications.

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