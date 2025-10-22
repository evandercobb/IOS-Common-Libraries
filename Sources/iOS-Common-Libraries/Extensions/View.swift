//
//  View.swift
//  iOS-Common-Libraries
//
//  Created by Dinesh Harjani on 9/8/22.
//  Copyright © 2022 Nordic Semiconductor. All rights reserved.
//

import SwiftUI

// MARK: - FormIniOSListInMacOS

#if os(iOS)
public typealias FormIniOSListInMacOS = Form
#elseif os(macOS)
public typealias FormIniOSListInMacOS = List
#endif

// MARK: - View

public extension View {
    
    // MARK: frame
    
    @inlinable func centered() -> some View {
        // Hack.
        return frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
    }
    
    @inlinable func frame(size: CGSize, alignment: Alignment = .center) -> some View {
        return frame(width: size.width, height: size.height, alignment: alignment)
    }
    
    @inlinable func centerTextInsideForm() -> some View {
        // Hack.
        return frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
    }
    
    @inlinable func withoutListRowInsets() -> some View {
        return listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    @available(iOS 16.0, macCatalyst 16.0, macOS 13.0, *)
    @inlinable func fixedListRowSeparatorPadding() -> some View {
        return alignmentGuide(.listRowSeparatorLeading) { dimension in
            dimension[.leading]
        }
    }
    
    // MARK: setAccent
    
    @inlinable func setAccent(_ color: Color) -> some View {
        return accentColor(color)
    }
    
    // MARK: - NavBar
    
    func setTitle(_ title: String) -> some View {
        #if os(iOS)
        return navigationBarTitle(title, displayMode: .inline)
        #else
        return navigationTitle(title)
        #endif
    }
    
    func setupNavBarBackground(with color: Color) -> some View {
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            let navigationBar = UINavigationBar.appearance()
            
            if #available(iOS 26.0, *) {
                navigationBar.barStyle = .default
                // In case of bar style .black, the barTintColor defines the color of the top part
                // of the screen (status bar area) when nav bar is collapsed.
                // For .default, it has no effect.
                // navigationBar.barTintColor = .nordicBlue
                
                // The NavigationBar background color just applies to the NavBar, not the status bar area.
                // navigationBar.backgroundColor = .nordicBlue
                
                navigationBar.isTranslucent = true
                navigationBar.prefersLargeTitles = true
                
                navBarAppearance.configureWithTransparentBackground()
                navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.dynamicColor(light: UIColor(.nordicBlue), dark: UIColor.white)]
                navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.dynamicColor(light: UIColor(.nordicBlue), dark: UIColor.white)]
            } else {
                navigationBar.barStyle = .default
                navigationBar.isTranslucent = false
                navigationBar.prefersLargeTitles = true
                // This changes the color of nav bar buttons.
                navigationBar.tintColor = .white
                
                navBarAppearance.configureWithOpaqueBackground()
                navBarAppearance.backgroundColor = UIColor.dynamicColor(light: UIColor(.nordicBlue), dark: .black)
                navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            }
            
            navigationBar.standardAppearance = navBarAppearance
            navigationBar.scrollEdgeAppearance = navBarAppearance
        } else {
            // For older versions the navigation bar settings are set in the storyboard.
        }
         return self
    }
    
    // MARK: - NavigationView
    
    @ViewBuilder
    func wrapInNavigationViewForiOS(with color: Color) -> some View {
        #if os(iOS)
        NavigationView {
            self
        }
        .setSingleColumnNavigationViewStyle()
        .setupNavBarBackground(with: color)
        .accentColor(.white)
        #else
        self
        #endif
    }
    
    // MARK: - UITextField
    
    func disableAllAutocorrections() -> some View {
        disableAutocorrection(true)
        #if os(iOS)
            .autocapitalization(.none)
        #endif
    }
}

// MARK: - dynamic()

extension UIColor {
    static func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { trait in
                trait.userInterfaceStyle == .dark ? dark : light
            }
        } else {
            return light
        }
    }
}

// MARK: - doOnce()

public extension View {
    
    func doOnce(_ action: @escaping () -> Void) -> some View {
        modifier(OnceOnly(action: action))
    }
}

private struct OnceOnly: ViewModifier {
    
    let action: () -> Void
    
    @State private var doneAlready = false
    
    func body(content: Content) -> some View {
        // And then, track it here
        content.onAppear {
            guard !doneAlready else { return }
            doneAlready = true
            action()
        }
    }
}

// MARK: - taskOnce()

public extension View {
    
    func taskOnce(_ asyncAction: @escaping () async -> Void) -> some View {
        modifier(TaskOnceOnly(asyncAction: asyncAction))
    }
}

private struct TaskOnceOnly: ViewModifier {
    
    @State private var doneAlready = false
    
    let asyncAction: () async -> Void
    
    func body(content: Content) -> some View {
        content.task {
            guard !doneAlready else { return }
            doneAlready = true
            await asyncAction()
        }
    }
}

// MARK: - Picker

public extension Picker {
    
    @ViewBuilder
    func setAsComboBoxStyle() -> some View {
        self
        #if os(iOS)
            .pickerStyle(MenuPickerStyle())
            .accentColor(.primary)
        #endif
    }
    
    func setAsSegmentedControlStyle() -> some View {
        self
        #if os(iOS)
            .pickerStyle(SegmentedPickerStyle())
        #endif
    }
}

// MARK: - DisclosureGroup

@available(iOS 16.0, macCatalyst 16.0, macOS 13.0, *)
public struct FixedOnTheRightStyle: DisclosureGroupStyle {
    
    public func makeBody(configuration: Configuration) -> some View {
        Button {
            withAnimation {
                configuration.isExpanded.toggle()
            }
        } label: {
            HStack(alignment: .firstTextBaseline) {
                configuration.label
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(size: CGSize(asSquare: 12.0))
                    .rotationEffect(.degrees(configuration.isExpanded ? 0 : 90))
                    .foregroundColor(.universalAccentColor)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        if configuration.isExpanded {
            configuration.content
                .padding(.leading)
                .transition(.move(edge: .top).combined(with: .asymmetric(insertion: .opacity.animation(.easeIn(duration: 0.6)), removal: .opacity.animation(.easeOut(duration: 0.1)))))
        }
    }
}

@available(iOS 16.0, macCatalyst 16.0, macOS 13.0, *)
public extension DisclosureGroupStyle where Self == FixedOnTheRightStyle {
    
    static var fixedOnTheRight: FixedOnTheRightStyle { .init() }
}

// MARK: - NavigationView

public extension NavigationView {
    
    func setSingleColumnNavigationViewStyle() -> some View {
        self
        #if os(iOS)
            .navigationViewStyle(.stack)
        #endif
    }
}
