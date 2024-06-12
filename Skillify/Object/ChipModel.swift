//
//  Chip.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 01.02.2024.
//

import Foundation
import SwiftUI

struct ChipModel: Identifiable {
    var isSelected: Bool
    let id = UUID()
    let systemImage: String
    let titleKey: String
}

class ChipsViewModel: ObservableObject {
    //    @Published var dataObject: [ChipModel] = [ChipModel.init(isSelected: false, systemImage: "pencil.circle", titleKey: "Pencil Circle")]
    //    var names: [Skill]
    @Published var chipArray: [ChipModel] = [
        ChipModel(isSelected: false, systemImage: "heart.circle", titleKey: "Programming"),
        ChipModel(isSelected: false, systemImage: "folder.circle", titleKey: "Graphic design"),
        ChipModel(isSelected: false, systemImage: "pencil.and.outline", titleKey: "Entrepreneurship"),
        ChipModel(isSelected: false, systemImage: "book.circle", titleKey: "Marketing")
    ]
    
    func updateChips(with skills: [Skill]) {
        chipArray = skills.map { skill in
            ChipModel(isSelected: false, systemImage: skill.iconName ?? "checkmark.circle", titleKey: skill.name)
        }
    }
    
    func resetChipArray(){
        chipArray = [
            ChipModel(isSelected: false, systemImage: "heart.circle", titleKey: "Programming"),
            ChipModel(isSelected: false, systemImage: "folder.circle", titleKey: "Graphic design"),
            ChipModel(isSelected: false, systemImage: "pencil.and.outline", titleKey: "Entrepreneurship"),
            ChipModel(isSelected: false, systemImage: "book.circle", titleKey: "Marketing")
        ]
    }
    
    //    init(dataArray: [Skill]) {
    //        names = dataArray
    //
    //        names.forEach { s in
    //            chipArray.append(ChipModel(isSelected: false, systemImage: "checkmark.circle", titleKey: s.name))
    //        }
    //    }
    //
    
    
    //    func addChip() {
    //        dataObject.append(ChipModel.init(isSelected: false, systemImage: "pencil.circle", titleKey: "Pencil"))
    //    }
    //
    //    func removeLast() {
    //        guard dataObject.count != 0 else {
    //            return
    //        }
    //        dataObject.removeLast()
    //    }
}
