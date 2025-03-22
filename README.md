# HorizontalFlowLayout

A SwiftUI component that arranges child views in a horizontal flow layout, automatically wrapping to new lines when the container width is exceeded. Each item in the flow layout takes its natural size based on its content.

## Features

- Horizontal flow layout with automatic line wrapping
- Each item sizes to fit its content
- Customizable spacing between items
- Support for various types of child views
- Built with SwiftUI ViewBuilder
- Efficient layout calculation
- Compatible with iOS 16.0 and newer

## Installation

### Swift Package Manager

Add the following dependency to your `Package.swift` file:

```swift
.package(url: "https://github.com/yourusername/HorizontalFlowLayout.git", from: "1.0.0")
```

Or add it directly through Xcode:
1. File > Swift Packages > Add Package Dependency
2. Enter the repository URL: `https://github.com/yourusername/HorizontalFlowLayout.git`
3. Select the version you want to install
4. Add the package to your target

## Usage

HorizontalFlowLayout is very easy to use and provides multiple ways to create layouts:

### Basic Usage with Data Collections

```swift
import SwiftUI
import HorizontalFlowLayout

struct ContentView: View {
    // Define an identifiable data model
    struct Tag: Identifiable {
        let id = UUID()
        let name: String
    }
    
    // Your data collection
    let tags = [
        Tag(name: "SwiftUI"),
        Tag(name: "Layout"),
        Tag(name: "Flow"),
        Tag(name: "Horizontal")
    ]
    
    var body: some View {
        HorizontalFlowLayout(tags, spacing: 8) { tag in
            Text(tag.name)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
        }
        .padding()
    }
}
```

### Using ViewFlowLayout for Arbitrary Views

If you need to use a variety of different views rather than a homogeneous collection, use the `ViewFlowLayout`:

```swift
ViewFlowLayout(spacing: 8) {
    Text("First item")
    Image(systemName: "star")
    Label("Labeled item", systemImage: "tag")
    Circle().frame(width: 40, height: 40)
}
```

### Customizing Spacing and Alignment

```swift
HorizontalFlowLayout(
    myItems,
    spacing: 12,
    alignment: .center
) { item in
    // Your view here
}
```

## Example

For a complete example, check out the `HorizontalFlowLayoutExampleView` included in the package:

```swift
import SwiftUI
import HorizontalFlowLayout

struct MyView: View {
    var body: some View {
        HorizontalFlowLayoutExampleView()
    }
}
```

## How It Works

The layout works by:
1. Measuring the container width
2. Measuring each child view's size
3. Calculating positions for each view
4. Positioning items in rows, wrapping to a new line when needed

## Requirements

- iOS 16.0+ / macOS 13.0+
- Swift 6.0+
- Xcode 15.0+

## License

HorizontalFlowLayout is available under the MIT license. See the LICENSE file for more info. 