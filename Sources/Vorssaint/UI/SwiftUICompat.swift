// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI
import AppKit

#if !compiler(>=5.9)

// MARK: - Animation Compatibility

extension Animation {
    public static var smooth: Animation { .easeInOut(duration: 0.35) }
    public static func smooth(duration: Double = 0.35, extraBounce: Double = 0) -> Animation {
        .easeInOut(duration: duration)
    }
    public static func spring(duration: Double = 0.55, bounce: Double = 0) -> Animation {
        .spring(response: duration, dampingFraction: 1.0 - bounce, blendDuration: 0)
    }
}

public enum AnimationCompletionCriteriaShim {
    case logicallyComplete
    case fullyComplete
}

public func withAnimation<Result>(
    _ animation: Animation? = .default,
    completionCriteria: AnimationCompletionCriteriaShim = .logicallyComplete,
    _ body: () throws -> Result,
    completion: @escaping () -> Void
) rethrows -> Result {
    let result = try withAnimation(animation, body)
    DispatchQueue.main.async {
        completion()
    }
    return result
}

extension AnyTransition {
    public static var blurReplace: AnyTransition { .opacity }
}

// MARK: - Font Compatibility

extension Font {
    public static func system(_ style: Font.TextStyle, design: Font.Design = .default, weight: Font.Weight) -> Font {
        Font.system(style, design: design).weight(weight)
    }
}

// MARK: - View Geometry & Layout Compatibility

struct GeometryChangePreferenceKey<T: Equatable>: PreferenceKey {
    static var defaultValue: T? { nil }
    static func reduce(value: inout T?, nextValue: () -> T?) {
        if let next = nextValue() { value = next }
    }
}

extension View {
    public func onGeometryChange<T: Equatable>(
        for type: T.Type,
        of transform: @escaping (GeometryProxy) -> T,
        action: @escaping (T) -> Void
    ) -> some View {
        self.background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: GeometryChangePreferenceKey<T>.self, value: transform(proxy))
            }
        )
        .onPreferenceChange(GeometryChangePreferenceKey<T>.self) { value in
            if let value {
                DispatchQueue.main.async {
                    action(value)
                }
            }
        }
    }
}

// MARK: - HoverPhase Compatibility

public enum HoverPhase {
    case active(CGPoint)
    case ended
}

// MARK: - SymbolEffect & Transition Shims

public struct SymbolEffectShim: Equatable {
    public static var bounce: SymbolEffectShim { SymbolEffectShim() }
    public static var variableColor: SymbolEffectShim { SymbolEffectShim() }
    public static var replace: SymbolEffectShim { SymbolEffectShim() }

    public var iterative: SymbolEffectShim { self }
    public var reversing: SymbolEffectShim { self }
}

public struct SymbolEffectOptionsShim: Equatable {
    public static var repeating: SymbolEffectOptionsShim { SymbolEffectOptionsShim() }
    public static func speed(_ speed: Double) -> SymbolEffectOptionsShim { SymbolEffectOptionsShim() }
}

public struct ContentTransitionShim: Equatable {
    public static func numericText(countsDown: Bool = false) -> ContentTransitionShim {
        ContentTransitionShim()
    }
    public static func symbolEffect(_ effect: SymbolEffectShim) -> ContentTransitionShim {
        ContentTransitionShim()
    }
}

// MARK: - Form Style Compatibility

public struct FormStyleShim: Equatable {
    public static let grouped = FormStyleShim()
    public static let columns = FormStyleShim()
}

// MARK: - Scroll Indicator Visibility Compatibility

public struct ScrollIndicatorVisibilityShim: Equatable {
    public static let automatic = ScrollIndicatorVisibilityShim()
    public static let visible = ScrollIndicatorVisibilityShim()
    public static let never = ScrollIndicatorVisibilityShim()
    public static let hidden = ScrollIndicatorVisibilityShim()
}

// MARK: - Focus Interactions Compatibility

public struct FocusInteractionsShim {
    public static var edit: FocusInteractionsShim { FocusInteractionsShim() }
    public static var activate: FocusInteractionsShim { FocusInteractionsShim() }
}

// MARK: - Menu Style Compatibility

public struct MenuStyleButtonShim {
    public static var button: MenuStyleButtonShim { MenuStyleButtonShim() }
}

// MARK: - Keyframe Compatibility

public struct CubicKeyframe<Value> {
    public init(_ value: Value, duration: Double) {}
}

public struct SpringKeyframe<Value> {
    public init(_ value: Value, duration: Double, spring: Animation = .default) {}
}

@resultBuilder
public struct KeyframesBuilderCompat {
    public static func buildBlock(_ components: Any...) -> KeyframesShim { KeyframesShim() }
    public static func buildExpression<T>(_ expression: T) -> Any { expression }
}

public struct KeyframesShim {}

// MARK: - View Modifiers (macOS 13/14+ Compatibility)

extension View {
    public func symbolEffect(_ effect: SymbolEffectShim, options: SymbolEffectOptionsShim? = nil, value: Any? = nil) -> some View {
        self
    }

    public func symbolEffect(_ effect: SymbolEffectShim, options: SymbolEffectOptionsShim? = nil, isActive: Bool = true) -> some View {
        self
    }

    public func symbolEffect(_ effect: SymbolEffectShim, isActive: Bool = true) -> some View {
        self
    }

    public func symbolEffect<T>(_ effect: T, options: Any? = nil, value: Any? = nil) -> some View {
        self
    }

    public func symbolEffect<T>(_ effect: T, options: Any? = nil, isActive: Bool = true) -> some View {
        self
    }

    public func symbolEffect<T>(_ effect: T, isActive: Bool = true) -> some View {
        self
    }

    public func scrollIndicators(_ visibility: ScrollIndicatorVisibilityShim, axes: Axis.Set = [.vertical, .horizontal]) -> some View {
        self
    }

    public func scrollIndicators(_ visibility: Any? = nil, axes: Axis.Set = [.vertical, .horizontal]) -> some View {
        self
    }

    public func scrollDisabled(_ disabled: Bool) -> some View {
        self
    }

    public func scrollContentBackground(_ visibility: Visibility) -> some View {
        self
    }

    public func scrollContentBackground(_ visibility: Any) -> some View {
        self
    }

    public func focusEffectDisabled(_ disabled: Bool = true) -> some View {
        self
    }

    public func contentTransition(_ transition: ContentTransitionShim) -> some View {
        self
    }

    public func contentTransition(_ transition: Any) -> some View {
        self
    }

    public func fontWeight(_ weight: Font.Weight?) -> some View {
        self
    }

    public func lineLimit(_ number: Int?, reservesSpace: Bool) -> some View {
        self.lineLimit(number)
    }

    public func formStyle(_ style: FormStyleShim) -> some View {
        self
    }

    public func formStyle<S>(_ style: S) -> some View {
        self
    }

    public func listRowSeparator(_ visibility: Visibility, edges: VerticalEdge.Set = .all) -> some View {
        self
    }

    public func listRowSeparator(_ visibility: Any, edges: VerticalEdge.Set = .all) -> some View {
        self
    }

    public func menuStyle(_ style: MenuStyleButtonShim) -> some View {
        self
    }

    public func tracking(_ tracking: CGFloat) -> some View {
        self
    }

    public func kerning(_ kerning: CGFloat) -> some View {
        self
    }

    public func onContinuousHover(
        coordinateSpace: CoordinateSpace = .local,
        perform action: @escaping (HoverPhase) -> Void
    ) -> some View {
        self.onHover { isHovering in
            action(isHovering ? .active(.zero) : .ended)
        }
    }

    public func dropDestination<T>(
        for payloadType: T.Type,
        action: @escaping ([T], CGPoint) -> Bool,
        isTargeted: ((Bool) -> Void)? = nil
    ) -> some View {
        self
    }

    public func onKeyPress(_ key: KeyEquivalent, action: @escaping () -> KeyPress.Result) -> some View {
        self
    }

    public func keyframeAnimator<Value>(
        initialValue: Value,
        trigger: AnyHashable? = nil,
        @ViewBuilder content: @escaping (Self, Value) -> some View,
        @KeyframesBuilderCompat keyframes: (Value) -> Any = { _ in () }
    ) -> some View {
        content(self, initialValue)
    }

    public func transaction<V: Equatable>(value: V, _ transform: @escaping (inout Transaction) -> Void) -> some View {
        self.transaction(transform)
    }

    public func focusable(interactions: FocusInteractionsShim) -> some View {
        self.focusable()
    }
}

// MARK: - KeyPress Compatibility

public struct KeyPress {
    public enum Result {
        case handled
        case ignored
    }
}

// MARK: - ViewThatFits Compatibility

public struct ViewThatFits<Content: View>: View {
    let content: Content

    public init(in axes: Axis.Set = [.horizontal, .vertical], @ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
    }
}

// MARK: - Grid & GridRow Compatibility

public struct Grid<Content: View>: View {
    let alignment: Alignment
    let horizontalSpacing: CGFloat?
    let verticalSpacing: CGFloat?
    let content: Content

    public init(
        alignment: Alignment = .center,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: alignment.horizontal, spacing: verticalSpacing) {
            content
        }
    }
}

public struct GridRow<Content: View>: View {
    let alignment: VerticalAlignment?
    let content: Content

    public init(alignment: VerticalAlignment? = nil, @ViewBuilder content: () -> Content) {
        self.alignment = alignment
        self.content = content()
    }

    public var body: some View {
        HStack(alignment: alignment ?? .center) {
            content
        }
    }
}

extension View {
    @inlinable
    public func gridColumnAlignment(_ alignment: HorizontalAlignment) -> some View {
        self
    }
    @inlinable
    public func gridCellColumns(_ count: Int) -> some View {
        self
    }
}

// MARK: - ContentUnavailableView Compatibility

public struct ContentUnavailableView<Label: View, Description: View, Actions: View>: View {
    let label: Label
    let description: Description
    let actions: Actions

    public init(
        @ViewBuilder label: () -> Label,
        @ViewBuilder description: () -> Description = { EmptyView() },
        @ViewBuilder actions: () -> Actions = { EmptyView() }
    ) {
        self.label = label()
        self.description = description()
        self.actions = actions()
    }

    public var body: some View {
        VStack(spacing: 8) {
            label
            description.foregroundColor(.secondary)
            actions
        }
    }
}

extension ContentUnavailableView where Label == SwiftUI.Label<Text, Image>, Description == Text?, Actions == EmptyView {
    public init(_ title: String, systemImage: String, description: Text? = nil) {
        self.init(
            label: { Label(title, systemImage: systemImage) },
            description: { description },
            actions: { EmptyView() }
        )
    }
}

// MARK: - UnevenRoundedRectangle & RectangleCornerRadii

public struct RectangleCornerRadii: Equatable, Sendable {
    public var topLeading: CGFloat
    public var bottomLeading: CGFloat
    public var bottomTrailing: CGFloat
    public var topTrailing: CGFloat

    public init(topLeading: CGFloat = 0, bottomLeading: CGFloat = 0, bottomTrailing: CGFloat = 0, topTrailing: CGFloat = 0) {
        self.topLeading = topLeading
        self.bottomLeading = bottomLeading
        self.bottomTrailing = bottomTrailing
        self.topTrailing = topTrailing
    }
}

public struct UnevenRoundedRectangle: Shape {
    public var cornerRadii: RectangleCornerRadii
    public var style: RoundedCornerStyle

    public init(cornerRadii: RectangleCornerRadii, style: RoundedCornerStyle = .continuous) {
        self.cornerRadii = cornerRadii
        self.style = style
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let tl = min(min(cornerRadii.topLeading, rect.width / 2), rect.height / 2)
        let tr = min(min(cornerRadii.topTrailing, rect.width / 2), rect.height / 2)
        let br = min(min(cornerRadii.bottomTrailing, rect.width / 2), rect.height / 2)
        let bl = min(min(cornerRadii.bottomLeading, rect.width / 2), rect.height / 2)

        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr), radius: tr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        path.addArc(center: CGPoint(x: rect.maxX - br, y: rect.maxY - br), radius: br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl), radius: bl, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        path.addArc(center: CGPoint(x: rect.minX + tl, y: rect.minY + tl), radius: tl, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.closeSubpath()
        return path
    }
}

// MARK: - AnyLayout, HStackLayout & VStackLayout

public struct AnyLayout {
    let isHStack: Bool
    let horizontalAlignment: VerticalAlignment
    let verticalAlignment: HorizontalAlignment
    let spacing: CGFloat?

    public init(_ layout: HStackLayout) {
        self.isHStack = true
        self.horizontalAlignment = layout.alignment
        self.verticalAlignment = .leading
        self.spacing = layout.spacing
    }

    public init(_ layout: VStackLayout) {
        self.isHStack = false
        self.horizontalAlignment = .center
        self.verticalAlignment = layout.alignment
        self.spacing = layout.spacing
    }

    public func callAsFunction<Content: View>(@ViewBuilder _ content: () -> Content) -> AnyView {
        if isHStack {
            return AnyView(HStack(alignment: horizontalAlignment, spacing: spacing, content: content))
        } else {
            return AnyView(VStack(alignment: verticalAlignment, spacing: spacing, content: content))
        }
    }
}

public struct HStackLayout {
    public let alignment: VerticalAlignment
    public let spacing: CGFloat?
    public init(alignment: VerticalAlignment = .center, spacing: CGFloat? = nil) {
        self.alignment = alignment
        self.spacing = spacing
    }
}

public struct VStackLayout {
    public let alignment: HorizontalAlignment
    public let spacing: CGFloat?
    public init(alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil) {
        self.alignment = alignment
        self.spacing = spacing
    }
}

// MARK: - ProposedViewSize Compatibility

public struct ProposedViewSize: Equatable, Sendable {
    public var width: CGFloat?
    public var height: CGFloat?
    public init(width: CGFloat?, height: CGFloat?) {
        self.width = width
        self.height = height
    }
    public static let unspecified = ProposedViewSize(width: nil, height: nil)
    public static let zero = ProposedViewSize(width: 0, height: 0)
    public static let infinity = ProposedViewSize(width: .infinity, height: .infinity)
}

// MARK: - NavigationSplitView Compatibility

public enum NavigationSplitViewVisibility: Sendable {
    case automatic
    case all
    case doubleColumn
    case detailOnly
}

public struct NavigationSplitView<Sidebar: View, Content: View, Detail: View>: View {
    let sidebar: Sidebar
    let content: Content
    let detail: Detail

    public init(
        columnVisibility: Binding<NavigationSplitViewVisibility>? = nil,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content,
        @ViewBuilder detail: () -> Detail
    ) {
        self.sidebar = sidebar()
        self.content = content()
        self.detail = detail()
    }

    public init(
        columnVisibility: Binding<NavigationSplitViewVisibility>? = nil,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder detail: () -> Detail
    ) where Content == EmptyView {
        self.sidebar = sidebar()
        self.content = EmptyView()
        self.detail = detail()
    }

    public var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            if !(content is EmptyView) {
                content
                Divider()
            }
            detail
        }
    }
}

public struct NavigationSplitViewStyleShim {
    public static var balanced: NavigationSplitViewStyleShim { NavigationSplitViewStyleShim() }
    public static var prominentDetail: NavigationSplitViewStyleShim { NavigationSplitViewStyleShim() }
}

extension View {
    public func navigationSplitViewColumnWidth(_ width: CGFloat) -> some View { self }
    public func navigationSplitViewColumnWidth(min: CGFloat? = nil, ideal: CGFloat? = nil, max: CGFloat? = nil) -> some View { self }
    public func navigationSplitViewStyle(_ style: NavigationSplitViewStyleShim) -> some View { self }
}

// MARK: - LabeledContent Compatibility

public struct LabeledContent<Label: View, Content: View>: View {
    let label: Label
    let content: Content

    public init(@ViewBuilder content: () -> Content, @ViewBuilder label: () -> Label) {
        self.content = content()
        self.label = label()
    }

    public var body: some View {
        HStack {
            label
            Spacer()
            content
        }
    }
}

extension LabeledContent where Label == Text {
    public init<S: StringProtocol>(_ title: S, @ViewBuilder content: () -> Content) {
        self.init(content: content, label: { Text(title) })
    }
}

// MARK: - onChange Compatibility (macOS 14 Syntax on macOS 12)

extension View {
    @inlinable
    public func onChange<V: Equatable>(
        of value: V,
        initial: Bool = false,
        _ action: @escaping (V, V) -> Void
    ) -> some View {
        self.modifier(ChangeObserver2(value: value, initial: initial, action: action))
    }

    @inlinable
    public func onChange<V: Equatable>(
        of value: V,
        initial: Bool = false,
        _ action: @escaping () -> Void
    ) -> some View {
        self.modifier(ChangeObserver0(value: value, initial: initial, action: action))
    }
}

public struct ChangeObserver2<V: Equatable>: ViewModifier {
    let value: V
    let initial: Bool
    let action: (V, V) -> Void
    @State private var previousValue: V?

    public init(value: V, initial: Bool, action: @escaping (V, V) -> Void) {
        self.value = value
        self.initial = initial
        self.action = action
    }

    public func body(content: Content) -> some View {
        content
            .onAppear {
                if initial {
                    action(value, value)
                }
                previousValue = value
            }
            .onChange(of: value) { newValue in
                let old = previousValue ?? newValue
                previousValue = newValue
                action(old, newValue)
            }
    }
}

public struct ChangeObserver0<V: Equatable>: ViewModifier {
    let value: V
    let initial: Bool
    let action: () -> Void

    public init(value: V, initial: Bool, action: @escaping () -> Void) {
        self.value = value
        self.initial = initial
        self.action = action
    }

    public func body(content: Content) -> some View {
        content
            .onAppear {
                if initial {
                    action()
                }
            }
            .onChange(of: value) { _ in
                action()
            }
    }
}

public struct NSHostingSizingOptions: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let minSize = NSHostingSizingOptions(rawValue: 1 << 0)
    public static let intrinsicContentSize = NSHostingSizingOptions(rawValue: 1 << 1)
    public static let maxSize = NSHostingSizingOptions(rawValue: 1 << 2)
    public static let preferredContentSize = NSHostingSizingOptions(rawValue: 1 << 3)
}

extension NSHostingView {
    public var sizingOptions: NSHostingSizingOptions {
        get { [] }
        set {}
    }
}

extension NSHostingController {
    public var sizingOptions: NSHostingSizingOptions {
        get { [] }
        set {}
    }
}

@MainActor
public final class ImageRenderer<Content: View> {
    public var content: Content
    public var scale: CGFloat = 1.0

    public init(content: Content) {
        self.content = content
    }

    public var cgImage: CGImage? {
        let view = NSHostingView(rootView: content)
        view.layoutSubtreeIfNeeded()
        let targetSize = view.fittingSize
        guard targetSize.width > 0 && targetSize.height > 0 else { return nil }
        let width = max(1, Int(targetSize.width * scale))
        let height = max(1, Int(targetSize.height * scale))
        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: width * 4,
            bitsPerPixel: 32
        ) else { return nil }
        bitmapRep.size = targetSize
        let context = NSGraphicsContext(bitmapImageRep: bitmapRep)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        view.frame = CGRect(origin: .zero, size: targetSize)
        view.displayIgnoringOpacity(view.bounds, in: context!)
        NSGraphicsContext.restoreGraphicsState()
        return bitmapRep.cgImage
    }
}

#endif
