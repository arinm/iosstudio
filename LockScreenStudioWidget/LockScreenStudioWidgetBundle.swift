import WidgetKit
import SwiftUI

@main
struct LockScreenStudioWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodoWidget()
        LockScreenTodoWidget()
        // Full-page portrait family only exists from iOS 27; on earlier
        // versions the bundle simply ships without it.
        if #available(iOS 27.0, *) {
            YearInPixelsWidget()
        }
    }
}
