//
//  AccentToolbar.swift
//  Tuali
//
//  Created by Angel HG on 06/06/26.
//

import SwiftUI

struct AccentToolbar<Leading: View, Trailing: View, BelowContent: View>: View {
    let kicker: String?
    let title: String
    let subtitle: String?
    let background: Color
    let leading: Leading
    let trailing: Trailing
    let belowContent: BelowContent

    init(
        kicker: String? = nil,
        title: String,
        subtitle: String? = nil,
        background: Color = .accent,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing,
        @ViewBuilder belowContent: () -> BelowContent
    ) {
        self.kicker = kicker
        self.title = title
        self.subtitle = subtitle
        self.background = background
        self.leading = leading()
        self.trailing = trailing()
        self.belowContent = belowContent()
    }

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                leading

                VStack(alignment: .leading, spacing: 4) {
                    if let kicker {
                        Text(kicker)
                            .font(.custom("Nexa-Heavy", size: 13, relativeTo: .footnote))
                            .foregroundStyle(.white.secondary)
                    }
                    Text(title)
                        .font(.custom("Nexa-Heavy", size: 24, relativeTo: .title))
                        .foregroundStyle(.white)
                    if let subtitle {
                        Text(subtitle)
                            .font(.custom("Nexa-Heavy", size: 13, relativeTo: .footnote))
                            .foregroundStyle(.white.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                trailing
            }
            .zIndex(0)

            belowContent
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(background)
    }
}

extension AccentToolbar where Leading == EmptyView, Trailing == EmptyView, BelowContent == EmptyView {
    init(
        kicker: String? = nil,
        title: String,
        subtitle: String? = nil,
        background: Color = .accent
    ) {
        self.init(
            kicker: kicker,
            title: title,
            subtitle: subtitle,
            background: background,
            leading: { EmptyView() },
            trailing: { EmptyView() },
            belowContent: { EmptyView() }
        )
    }
}

extension AccentToolbar where Leading == EmptyView, Trailing == EmptyView {
    init(
        kicker: String? = nil,
        title: String,
        subtitle: String? = nil,
        background: Color = .accent,
        @ViewBuilder belowContent: () -> BelowContent
    ) {
        self.init(
            kicker: kicker,
            title: title,
            subtitle: subtitle,
            background: background,
            leading: { EmptyView() },
            trailing: { EmptyView() },
            belowContent: belowContent
        )
    }
}

extension AccentToolbar where Leading == EmptyView, BelowContent == EmptyView {
    init(
        kicker: String? = nil,
        title: String,
        subtitle: String? = nil,
        background: Color = .accent,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(
            kicker: kicker,
            title: title,
            subtitle: subtitle,
            background: background,
            leading: { EmptyView() },
            trailing: trailing,
            belowContent: { EmptyView() }
        )
    }
}

extension AccentToolbar where Leading == EmptyView {
    init(
        kicker: String? = nil,
        title: String,
        subtitle: String? = nil,
        background: Color = .accent,
        @ViewBuilder trailing: () -> Trailing,
        @ViewBuilder belowContent: () -> BelowContent
    ) {
        self.init(
            kicker: kicker,
            title: title,
            subtitle: subtitle,
            background: background,
            leading: { EmptyView() },
            trailing: trailing,
            belowContent: belowContent
        )
    }
}

extension AccentToolbar where Trailing == EmptyView {
    init(
        kicker: String? = nil,
        title: String,
        subtitle: String? = nil,
        background: Color = .accent,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder belowContent: () -> BelowContent
    ) {
        self.init(
            kicker: kicker,
            title: title,
            subtitle: subtitle,
            background: background,
            leading: leading,
            trailing: { EmptyView() },
            belowContent: belowContent
        )
    }
}
