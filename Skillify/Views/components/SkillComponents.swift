//
//  SkillComponents.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/7/25.
//

import SwiftUI

// MARK: - Category Chip
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.newBlue : Color.gray.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

// MARK: - Skill Card
struct SkillCard: View {
    let skill: Skill
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: skill.iconName ?? "star.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(isSelected ? .white : .newBlue)
                
                Text(skill.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.newBlue : Color.gray.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.newBlue : Color.clear, lineWidth: 2)
            )
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .disabled(isDisabled)
    }
}

// MARK: - Selected Skill Card
struct SelectedSkillCard: View {
    let userSkill: UserSkill
    let onRemove: () -> Void
    let onLevelTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: userSkill.skill.iconName ?? "star.fill")
                .font(.system(size: 24))
                .foregroundStyle(.newBlue)
                .frame(width: 40, height: 40)
                .background(Color.newBlue.opacity(0.1))
                .cornerRadius(8)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(userSkill.skill.name)
                    .font(.body)
                    .fontWeight(.semibold)
                
                if let level = userSkill.level {
                    Text("\(level.emoji) \(level.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Level button
            Button {
                onLevelTap()
            } label: {
                HStack(spacing: 4) {
                    if let level = userSkill.level {
                        Text(level.emoji)
                    } else {
                        Text("Select")
                            .font(.caption)
                    }
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .foregroundStyle(.newBlue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.newBlue.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Remove button
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 20))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Level Picker Sheet
struct LevelPickerSheet: View {
    let skill: Skill
    let currentLevel: SkillLevel?
    let onSelect: (SkillLevel) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: skill.iconName ?? "star.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.newBlue)
                
                Text(skill.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Select your skill level")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top)
            
            // Level options
            VStack(spacing: 12) {
                ForEach(SkillLevel.allCases, id: \.self) { level in
                    Button {
                        onSelect(level)
                        dismiss()
                    } label: {
                        HStack {
                            Text(level.emoji)
                                .font(.title2)
                            
                            Text(level.rawValue)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            if currentLevel == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.newBlue)
                            }
                        }
                        .foregroundStyle(.primary)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(currentLevel == level ? Color.newBlue.opacity(0.1) : Color.gray.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(currentLevel == level ? Color.newBlue : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

// MARK: - Desired Skill Chip
struct DesiredSkillChip: View {
    let skill: Skill
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: skill.iconName ?? "star.fill")
                .font(.system(size: 14))
            
            Text(skill.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.newBlue)
        )
    }
}

// MARK: - WrappingHStack Layout (iOS 16+)
/// A layout that places subviews left-to-right and wraps to the next line when needed.
struct WrappingHStack: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX > 0 && currentX + size.width > maxWidth {
                // wrap to next line
                currentX = 0
                currentY += rowHeight + lineSpacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }

        return CGSize(width: maxWidth, height: currentY + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX > 0 && currentX + size.width > maxWidth {
                // wrap
                currentX = 0
                currentY += rowHeight + lineSpacing
                rowHeight = 0
            }
            let origin = CGPoint(x: bounds.minX + currentX, y: bounds.minY + currentY)
            subview.place(at: origin, proposal: ProposedViewSize(width: size.width, height: size.height))
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

