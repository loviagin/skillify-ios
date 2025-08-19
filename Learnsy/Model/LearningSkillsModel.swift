//
//  LearningSkillsModel.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 20.12.2023.
//

import Foundation
import SwiftUI

class LearningSkillsViewModel: ObservableObject {
    private let maxSkillsAllowed = 5
    
    @Published var skills: [Skill]
    @Published var searchText = ""
    private var authViewModel: AuthViewModel?
    
    init(skills: [Skill] = []) {
        self.skills = [
            Skill(name: "Graphic Design", iconName: "paintbrush.pointed"),
            Skill(name: "Photography", iconName: "camera"),
            Skill(name: "Web Design", iconName: "desktopcomputer"),
            Skill(name: "Cooking", iconName: "fork.knife"),
            Skill(name: "Programming", iconName: "laptopcomputer"),
            Skill(name: "Fitness", iconName: "figure.stand"),
            Skill(name: "Yoga", iconName: "figure.walk"),
            Skill(name: "Sewing", iconName: "scissors"),
            Skill(name: "Dancing", iconName: "figure.wave"),
            Skill(name: "Painting", iconName: "paintpalette"),
            Skill(name: "Financial", iconName: "banknote"),
            Skill(name: "Marketing", iconName: "megaphone"),
            Skill(name: "Development", iconName: "brain"),
            Skill(name: "Psychology", iconName: "heart.text.square"),
            Skill(name: "Sociology", iconName: "person.2"),
            Skill(name: "Writing", iconName: "pencil"),
            Skill(name: "Public Speaking", iconName: "speaker.wave.3"),
            Skill(name: "Project Management", iconName: "chart.bar.doc.horizontal"),
            Skill(name: "Entrepreneurship", iconName: "briefcase"),
            Skill(name: "Gardening", iconName: "leaf.arrow.circlepath"),
            Skill(name: "Self-Defense", iconName: "shield"),
            Skill(name: "Knitting", iconName: "laurel.trailing"),
            Skill(name: "Jewelry Making", iconName: "rectangle.fill"),
            Skill(name: "Meditation", iconName: "hand.raised.fingers.spread.fill"),
            Skill(name: "Astronomy", iconName: "bubbles.and.sparkles"),
            Skill(name: "Karate", iconName: "hand.raised.fingers.spread.fill"),
            Skill(name: "Boxing", iconName: "square.stack.3d.forward.dottedline"),
            Skill(name: "Ballet", iconName: "figure.walk.diamond"),
            Skill(name: "Salsa", iconName: "figure.dance"),
            Skill(name: "Singing", iconName: "music.mic"),
            Skill(name: "Music Recording", iconName: "mic"),
            Skill(name: "Video Creation", iconName: "video"),
            Skill(name: "Drum Playing", iconName: "shareplay"),
            Skill(name: "Violin Playing", iconName: "play.square.stack"),
            Skill(name: "Piano Playing", iconName: "pianokeys"),
            Skill(name: "Manicure", iconName: "hand.raised"),
            Skill(name: "Makeup", iconName: "paintbrush"),
            Skill(name: "Running", iconName: "figure.run"),
            Skill(name: "Cycling", iconName: "bicycle"),
            Skill(name: "Swimming", iconName: "waveform.path.ecg"),
            Skill(name: "Tennis", iconName: "tennisball"),
            Skill(name: "Chess", iconName: "checkerboard.rectangle"),
            Skill(name: "Golf", iconName: "figure.golf"),
            Skill(name: "Surfing", iconName: "surfboard"),
            Skill(name: "Sailing", iconName: "sailboat"),
            Skill(name: "Drawing", iconName: "pencil.tip"),
            Skill(name: "Sculpture", iconName: "hammer"),
            Skill(name: "Calligraphy", iconName: "pencil.and.outline"),
            Skill(name: "Comedy", iconName: "theatermasks"),
            Skill(name: "Blogging", iconName: "square.and.pencil"),
            Skill(name: "SEO", iconName: "magnifyingglass"),
            Skill(name: "Social Media Management", iconName: "person.3.sequence"),
            Skill(name: "Mobile Photography", iconName: "iphone"),
            Skill(name: "Digital Art", iconName: "ipad"),
            Skill(name: "Juggling", iconName: "circles.hexagongrid"),
            Skill(name: "Magic", iconName: "wand.and.stars"),
            Skill(name: "Political Science", iconName: "building.columns"),
            Skill(name: "Electronics", iconName: "cpu"),
            Skill(name: "Automotive", iconName: "car.2"),
            Skill(name: "Music", iconName: "music.note"),
            Skill(name: "Guitar", iconName: "guitars"),
            Skill(name: "Sports", iconName: "sportscourt"),
            Skill(name: "Languages", iconName: "character.book.closed"),
            Skill(name: "Graffiti", iconName: "sparkles"),
            Skill(name: "Fishing", iconName: "fish"),
            Skill(name: "Modeling", iconName: "cube.transparent"),
            Skill(name: "Accounting", iconName: "sum"),
            Skill(name: "Ceramics", iconName: "cup.and.saucer"),
            Skill(name: "Acting", iconName: "theatermasks"),
            Skill(name: "Hiking", iconName: "map"),
            Skill(name: "Snowboarding", iconName: "figure.snowboarding"),
            Skill(name: "Woodworking", iconName: "wrench.and.screwdriver"),
            Skill(name: "Robotics", iconName: "car.side.fill"),
            Skill(name: "Physics", iconName: "atom"),
            Skill(name: "Skiing", iconName: "figure.skiing.downhill"),
            Skill(name: "Biology", iconName: "leaf"),
            Skill(name: "Chemistry", iconName: "flask"),
            Skill(name: "History", iconName: "books.vertical"),
            Skill(name: "Mathematics", iconName: "plus"),
            Skill(name: "Literature", iconName: "book.closed"),
            Skill(name: "Philosophy", iconName: "brain.head.profile"),
            Skill(name: "Economics", iconName: "scalemass"),
            Skill(name: "Consulting", iconName: "person.crop.circle.badge.checkmark"),
            Skill(name: "Startups", iconName: "plus.circle"),
            Skill(name: "Kitesurfing", iconName: "figure.surfing"),
            Skill(name: "Streaming", iconName: "livephoto.play")
        ]
    }
    
    func setAuthViewModel(_ authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }
    
    var filteredSkills: [Skill] {
        if searchText.isEmpty {
            return skills
        } else {
            return skills.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    func originalIndex(forFilteredIndex filteredIndex: Int) -> Int? {
        let filteredSkill = filteredSkills[filteredIndex]
        return skills.firstIndex(where: { $0.id == filteredSkill.id })
    }
    
    func selectSkill(_ skill: Skill) {
        if let index = skills.firstIndex(where: { $0.name == skill.name }) {
            if skills[index].level != nil {
                skills[index].isSelected = false // Снимаем выбор
                skills[index].level = nil
                if let ind = authViewModel?.currentUser?.learningSkills.firstIndex(where: { $0.name == skill.name }) {
                    authViewModel?.currentUser?.learningSkills.remove(at: ind)
                }
                authViewModel?.syncWithFirebase()
            } else if skills.filter({ $0.level != nil }).count < maxSkillsAllowed {
                skills.indices.forEach { skills[$0].isSelected = false }
                skills[index].isSelected.toggle() // Выбираем навык
            } else {
                // Показать сообщение об ошибке или предупреждение, если выбрано максимальное количество навыков
                print("Максимальное количество выбранных навыков - \(maxSkillsAllowed).")
                showAlertDialog()
            }
        }
    }
    
    func showAlertDialog() {
        // Создайте UIAlertController
        let alertController = UIAlertController(title: "Learnsy", message: "You can choose up to 5 skills", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Ok", style: .cancel) { (action) in
            alertController.dismiss(animated: true, completion: nil) // Закрыть UIAlertController
        }
        
        // Добавьте действия к UIAlertContr
        alertController.addAction(cancelAction)
        
        // Получите доступ к текущему UIViewController (например, через navigationController или tabBarController)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first,
           let currentViewController = window.rootViewController {
            // Отобразите UIAlertController
            currentViewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    func deselectSkill() {
        for index in skills.indices {
            skills[index].isSelected = false
        }
    }
    
    func updateSkills(with userSkills: [Skill]) {
        for userSkill in userSkills {
            if let index = skills.firstIndex(where: { $0.name == userSkill.name }) {
                skills[index].level = userSkill.level
            }
        }
    }
}

