# Neshan Navigation App
![ScreenRecording_09-08-202414-26-58_1-ezgif com-optimize](https://github.com/user-attachments/assets/a493f413-b5a2-490e-b137-00ed8af57b4d)

This iOS application integrates with the **Neshan API** to provide powerful search and routing functionalities. Built on **Apple's MapKit**, the app offers a seamless experience for users to search for nearby locations and get directions based on their current location.

## Features

- **Search Nearby Locations**: Users can search for nearby places based on their current location using the Neshan API.
- **Save Favorite Locations**: Users can save their favorite or frequently visited locations, stored locally using **Core Data**.
- **Route Navigation**: Provides routing functionality to guide users from their current location to any selected destination on the map.
- **MVVM Architecture**: The app is structured using the **Model-View-ViewModel (MVVM)** pattern, ensuring a clean separation of concerns and maintainability.
- **Dynamic App Icon**: The app icon automatically updates in **iOS 18** to support Dark Mode and other system appearance changes.

## Technologies Used

- **Neshan API**: Integrated for search and routing capabilities.
- **MapKit**: Apple's native framework for displaying maps and handling user interactions.
- **Core Data**: Used for saving and managing user data locally.
- **MVVM Architecture**: For better code organization, reusability, and testability.
- **Dynamic App Icons**: The app icon adapts to system appearance changes in iOS 18, including support for Dark Mode.

## How It Works

1. Users can search for nearby locations based on their current location.
2. The app shows the results on the map using **MapKit**.
3. Users can select a place and get a route from their current location to the selected place.
4. Users can save places to their favorites, which will be stored locally with **Core Data** for later use.
5. The app icon dynamically updates in iOS 18 to reflect Dark Mode and appearance changes.
