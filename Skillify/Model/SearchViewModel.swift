//
//  SearchViewMdel.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 02.02.2024.
//

import Foundation
import SwiftUI
import FirebaseFirestore

class SearchViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var skills: [Skill]
    @Published var chipArray: [ChipModel] {
        didSet {
            fetchUsers() // Перезагружаем пользователей при каждом изменении chipArray
        }
    }
    @Published var isLearning: Bool = true
    
    var authViewModel: AuthViewModel? = nil

    init(chipArray: [ChipModel]) {
        self.chipArray = chipArray
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
        self.fetchUsers()
    }
    
    func toggleChipSelection(at index: Int) {
        chipArray[index].isSelected.toggle()
        fetchUsers()
    }
    
    func fetchUsers() {
        Firestore.firestore().collection("users").getDocuments { snapshot, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            // Получаем только выбранные значения из chipArray
            let selectedSkills = self.chipArray.filter { $0.isSelected }.map { $0.titleKey }
            
            if selectedSkills.isEmpty {
                self.users = documents.compactMap { doc -> User? in
                    let user = try? doc.data(as: User.self)
                    
                    if let u = user {
                        var isBlocked = true
                        if let model = self.authViewModel?.currentUser, model.blockedUsers.contains(u.id){
                            isBlocked = false
                        }
                        
                        return (!u.first_name.isEmpty && u.block == nil && (!u.selfSkills.isEmpty || !u.learningSkills.isEmpty) && isBlocked) ? u : nil
                    }
                    return nil
                }
            } else {
                self.users = documents.compactMap { doc -> User? in
                    let user = try? doc.data(as: User.self)
                    
                    // Возвращаем пользователя, если хотя бы один из его навыков совпадает с выбранными
                    if let u = user {
                        var hasMatchingSkill: Bool
                        
                        if u.block != nil {
                            return nil
                        }
                        
                        if let model = self.authViewModel, model.currentUser!.blockedUsers.contains(u.id) {
                            return nil
                        }
                        
                        if self.isLearning {
                            hasMatchingSkill = u.learningSkills.contains { skill in
                                selectedSkills.contains(skill.name)
                            }
                        } else {
                            hasMatchingSkill = u.selfSkills.contains { skill in
                                selectedSkills.contains(skill.name)
                            }
                        }
                        return hasMatchingSkill ? u : nil
                    }
                    return nil
                }
            }
        }
    }
    
    func switchSearchType(learning: Bool, skills: [ChipModel]){
        chipArray = skills
        isLearning = learning
    }
    
    func resetSelection() {
        for index in skills.indices {
            skills[index].isSelected = false
        }
    }
    
    // Добавьте любые другие методы, необходимые для обновления chipArray
    // Например, метод для изменения isSelected у конкретного Chip
    func updateChipSelection(at index: Int) {
        guard skills.indices.contains(index) else { return }
        chipArray = []
        chipArray.append(ChipModel(isSelected: true, systemImage: "checkmark.circle", titleKey: skills[index].name))
        fetchUsers()
        // Нет необходимости вызывать fetchUsers() здесь, так как didSet для chipArray сделает это автоматически
    }
}
