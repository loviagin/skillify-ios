//
//  ChipsViewModel.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/17/24.
//

import Foundation

class ChipsViewModel: ObservableObject {
    @Published var chipArray: [ChipModel] = [
        ChipModel(isSelected: false, systemImage: "heart", titleKey: "Programming"),
        ChipModel(isSelected: false, systemImage: "folder", titleKey: "Graphic design"),
        ChipModel(isSelected: false, systemImage: "book", titleKey: "Marketing")
    ]
    
    func updateChips(with skills: [Skill]) {
        chipArray = skills.map { skill in
            ChipModel(isSelected: false, systemImage: skill.iconName ?? "checkmark", titleKey: skill.name)
        }
    }
    
    func resetChipArray(){
        chipArray = [
            ChipModel(isSelected: false, systemImage: "heart", titleKey: "Programming"),
            ChipModel(isSelected: false, systemImage: "folder", titleKey: "Graphic design"),
            ChipModel(isSelected: false, systemImage: "book", titleKey: "Marketing")
        ]
    }
}
