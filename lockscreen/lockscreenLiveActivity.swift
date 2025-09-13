//
//  lockscreenLiveActivity.swift
//  lockscreen
//
//  Created by Kris Lin on 2025/9/13.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct lockscreenAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct lockscreenLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: lockscreenAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension lockscreenAttributes {
    fileprivate static var preview: lockscreenAttributes {
        lockscreenAttributes(name: "World")
    }
}

extension lockscreenAttributes.ContentState {
    fileprivate static var smiley: lockscreenAttributes.ContentState {
        lockscreenAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: lockscreenAttributes.ContentState {
         lockscreenAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: lockscreenAttributes.preview) {
   lockscreenLiveActivity()
} contentStates: {
    lockscreenAttributes.ContentState.smiley
    lockscreenAttributes.ContentState.starEyes
}
