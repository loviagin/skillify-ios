//
//  Skill.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/7/25.
//

import Foundation

struct Skill: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let iconName: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case iconName = "icon_name"
    }
}

// Уровни владения навыком
enum SkillLevel: String, Codable, CaseIterable {
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"
    
    var color: String {
        switch self {
        case .bronze: return "green"
        case .silver: return "blue"
        case .gold: return "purple"
        }
    }
    
    var emoji: String {
        switch self {
        case .bronze: return "🌱"
        case .silver: return "🔷"
        case .gold: return "⭐️"
        }
    }
}

// Навык пользователя с уровнем
struct UserSkill: Codable, Identifiable, Hashable {
    var id: String { skill.id }
    let skill: Skill
    let level: SkillLevel?
    
    enum CodingKeys: String, CodingKey {
        case skill
        case level
    }
}

// Предопределенные навыки
extension Skill {
    static let predefinedSkills: [Skill] = [
        // Languages
        Skill(id: "english", name: "English", category: "Languages", iconName: "globe"),
        Skill(id: "spanish", name: "Spanish", category: "Languages", iconName: "globe"),
        Skill(id: "french", name: "French", category: "Languages", iconName: "globe"),
        Skill(id: "german", name: "German", category: "Languages", iconName: "globe"),
        Skill(id: "chinese", name: "Chinese", category: "Languages", iconName: "globe"),
        Skill(id: "japanese", name: "Japanese", category: "Languages", iconName: "globe"),
        
        // Business
        Skill(id: "marketing", name: "Marketing", category: "Business", iconName: "megaphone.fill"),
        Skill(id: "sales", name: "Sales", category: "Business", iconName: "chart.line.uptrend.xyaxis"),
        Skill(id: "management", name: "Management", category: "Business", iconName: "person.2.fill"),
        Skill(id: "accounting", name: "Accounting", category: "Business", iconName: "dollarsign.circle.fill"),
        Skill(id: "leadership", name: "Leadership", category: "Business", iconName: "star.fill"),
        
        // Creative
        Skill(id: "photography", name: "Photography", category: "Creative", iconName: "camera.fill"),
        Skill(id: "videography", name: "Videography", category: "Creative", iconName: "video.fill"),
        Skill(id: "writing", name: "Writing", category: "Creative", iconName: "pencil"),
        Skill(id: "drawing", name: "Drawing", category: "Creative", iconName: "paintbrush.fill"),
        Skill(id: "music", name: "Music", category: "Creative", iconName: "music.note"),
        Skill(id: "singing", name: "Singing", category: "Creative", iconName: "mic.fill"),
        
        // Design
        Skill(id: "figma", name: "Figma", category: "Design", iconName: "paintpalette.fill"),
        Skill(id: "photoshop", name: "Photoshop", category: "Design", iconName: "photo.fill"),
        Skill(id: "illustrator", name: "Illustrator", category: "Design", iconName: "paintbrush.fill"),
        Skill(id: "uxui", name: "UX/UI Design", category: "Design", iconName: "slider.horizontal.3"),
        
        // Sports & Fitness
        Skill(id: "yoga", name: "Yoga", category: "Sports", iconName: "figure.mind.and.body"),
        Skill(id: "running", name: "Running", category: "Sports", iconName: "figure.run"),
        Skill(id: "swimming", name: "Swimming", category: "Sports", iconName: "figure.pool.swim"),
        Skill(id: "cycling", name: "Cycling", category: "Sports", iconName: "bicycle"),
        Skill(id: "gym", name: "Gym Training", category: "Sports", iconName: "dumbbell.fill"),
        
        // Cooking & Food
        Skill(id: "cooking", name: "Cooking", category: "Cooking", iconName: "frying.pan.fill"),
        Skill(id: "baking", name: "Baking", category: "Cooking", iconName: "birthday.cake.fill"),
        Skill(id: "barista", name: "Barista Skills", category: "Cooking", iconName: "cup.and.saucer.fill"),
        
        // IT & Programming (меньше чем раньше)
        Skill(id: "swift", name: "Swift", category: "Programming", iconName: "swift"),
        Skill(id: "python", name: "Python", category: "Programming", iconName: "chevron.left.forwardslash.chevron.right"),
        Skill(id: "javascript", name: "JavaScript", category: "Programming", iconName: "curlybraces"),
        Skill(id: "webdev", name: "Web Development", category: "Programming", iconName: "globe"),
        
        // Communication
        Skill(id: "public_speaking", name: "Public Speaking", category: "Communication", iconName: "person.wave.2.fill"),
        Skill(id: "presentation", name: "Presentations", category: "Communication", iconName: "chart.bar.doc.horizontal.fill"),
        Skill(id: "storytelling", name: "Storytelling", category: "Communication", iconName: "text.bubble.fill"),
        
        // Music Instruments
        Skill(id: "guitar", name: "Guitar", category: "Music", iconName: "guitars.fill"),
        Skill(id: "piano", name: "Piano", category: "Music", iconName: "pianokeys"),
        Skill(id: "drums", name: "Drums", category: "Music", iconName: "music.note"),
        Skill(id: "violin", name: "Violin", category: "Music", iconName: "music.quarternote.3"),
        
        // Dance
        Skill(id: "ballet", name: "Ballet", category: "Dance", iconName: "figure.dance"),
        Skill(id: "salsa", name: "Salsa", category: "Dance", iconName: "figure.dance"),
        Skill(id: "hiphop", name: "Hip-Hop", category: "Dance", iconName: "figure.dance"),
        Skill(id: "contemporary", name: "Contemporary", category: "Dance", iconName: "figure.dance"),
        
        // Crafts & Handmade
        Skill(id: "sewing", name: "Sewing", category: "Crafts", iconName: "scissors"),
        Skill(id: "knitting", name: "Knitting", category: "Crafts", iconName: "scissors"),
        Skill(id: "woodworking", name: "Woodworking", category: "Crafts", iconName: "hammer.fill"),
        Skill(id: "pottery", name: "Pottery", category: "Crafts", iconName: "cube.fill"),
        Skill(id: "jewelry", name: "Jewelry Making", category: "Crafts", iconName: "sparkles"),
        
        // Professional Skills
        Skill(id: "project_management", name: "Project Management", category: "Professional", iconName: "calendar"),
        Skill(id: "time_management", name: "Time Management", category: "Professional", iconName: "clock.fill"),
        Skill(id: "teamwork", name: "Teamwork", category: "Professional", iconName: "person.2.fill"),
        Skill(id: "problem_solving", name: "Problem Solving", category: "Professional", iconName: "lightbulb.fill"),
        Skill(id: "critical_thinking", name: "Critical Thinking", category: "Professional", iconName: "brain.head.profile"),
        
        // Teaching & Education
        Skill(id: "teaching", name: "Teaching", category: "Education", iconName: "book.fill"),
        Skill(id: "tutoring", name: "Tutoring", category: "Education", iconName: "person.and.background.dotted"),
        Skill(id: "mentoring", name: "Mentoring", category: "Education", iconName: "person.2.badge.gearshape.fill"),
        
        // Technical (non-IT)
        Skill(id: "auto_repair", name: "Auto Repair", category: "Technical", iconName: "car.fill"),
        Skill(id: "electronics", name: "Electronics", category: "Technical", iconName: "powerplug.fill"),
        Skill(id: "plumbing", name: "Plumbing", category: "Technical", iconName: "wrench.adjustable.fill"),
        Skill(id: "carpentry", name: "Carpentry", category: "Technical", iconName: "hammer.fill"),
        
        // Health & Wellness
        Skill(id: "meditation", name: "Meditation", category: "Wellness", iconName: "brain.head.profile"),
        Skill(id: "nutrition", name: "Nutrition", category: "Wellness", iconName: "leaf.fill"),
        Skill(id: "massage", name: "Massage Therapy", category: "Wellness", iconName: "hand.raised.fill"),
        Skill(id: "personal_training", name: "Personal Training", category: "Wellness", iconName: "figure.run"),
        
        // Entertainment
        Skill(id: "acting", name: "Acting", category: "Entertainment", iconName: "theatermasks.fill"),
        Skill(id: "comedy", name: "Comedy", category: "Entertainment", iconName: "face.smiling.fill"),
        Skill(id: "magic", name: "Magic Tricks", category: "Entertainment", iconName: "wand.and.stars"),
        
        // Gaming & Esports
        Skill(id: "chess", name: "Chess", category: "Games", iconName: "square.grid.3x3.fill"),
        Skill(id: "poker", name: "Poker", category: "Games", iconName: "suit.club.fill"),
        Skill(id: "esports", name: "Esports", category: "Games", iconName: "gamecontroller.fill"),
        
        // Outdoor & Adventure
        Skill(id: "hiking", name: "Hiking", category: "Outdoor", iconName: "mountain.2.fill"),
        Skill(id: "camping", name: "Camping", category: "Outdoor", iconName: "tent.fill"),
        Skill(id: "fishing", name: "Fishing", category: "Outdoor", iconName: "fish.fill"),
        Skill(id: "climbing", name: "Rock Climbing", category: "Outdoor", iconName: "figure.climbing"),
        Skill(id: "surfing", name: "Surfing", category: "Outdoor", iconName: "water.waves"),
        Skill(id: "skiing", name: "Skiing", category: "Outdoor", iconName: "figure.skiing.downhill"),
        
        // Science & Research
        Skill(id: "data_analysis", name: "Data Analysis", category: "Science", iconName: "chart.bar.fill"),
        Skill(id: "research", name: "Research", category: "Science", iconName: "doc.text.magnifyingglass"),
        Skill(id: "lab_work", name: "Laboratory Work", category: "Science", iconName: "flask.fill"),
        
        // Social & Volunteer
        Skill(id: "volunteering", name: "Volunteering", category: "Social", iconName: "heart.fill"),
        Skill(id: "counseling", name: "Counseling", category: "Social", iconName: "bubble.left.and.bubble.right.fill"),
        Skill(id: "social_work", name: "Social Work", category: "Social", iconName: "person.2.fill"),
        
        // Other
        Skill(id: "driving", name: "Driving", category: "Other", iconName: "car.fill"),
        Skill(id: "gardening", name: "Gardening", category: "Other", iconName: "leaf.fill"),
        Skill(id: "diy", name: "DIY & Repairs", category: "Other", iconName: "hammer.fill"),
        Skill(id: "first_aid", name: "First Aid", category: "Other", iconName: "cross.case.fill"),
        Skill(id: "pet_care", name: "Pet Care", category: "Other", iconName: "pawprint.fill"),
        Skill(id: "babysitting", name: "Babysitting", category: "Other", iconName: "figure.2.and.child.holdinghands"),
    ]
}

