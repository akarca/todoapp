import AppKit
import SwiftUI

struct SelectionHighlightTuner: NSViewRepresentable {
    let isEnabled: Bool
    var toolTip: String = ""

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        apply(from: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        apply(from: nsView)
    }

    private func apply(from view: NSView) {
        DispatchQueue.main.async {
            var rowView: NSTableRowView?
            var ancestor = view.superview
            while let current = ancestor {
                if current is NSTableRowView && rowView == nil {
                    rowView = current as? NSTableRowView
                }
                if let tableView = current as? NSTableView {
                    tableView.selectionHighlightStyle = isEnabled ? .sourceList : .none
                    break
                }
                ancestor = current.superview
            }
            rowView?.toolTip = toolTip.isEmpty ? nil : toolTip
        }
    }
}
