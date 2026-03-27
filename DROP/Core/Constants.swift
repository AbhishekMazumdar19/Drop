import Foundation

// MARK: - Firestore Collection Names
enum Collections {
    static let users          = "users"
    static let drops          = "drops"
    static let dropResponses  = "dropResponses"
    static let comments       = "comments"
    static let conversations  = "conversations"
    static let messages       = "messages"
    static let campuses       = "campuses"
    static let zones          = "zones"
    static let notifications  = "notifications"
}

// MARK: - Storage Paths
enum StoragePaths {
    static func profileImage(userId: String) -> String { "profileImages/\(userId)/profile.jpg" }
    static func dropImage(userId: String, responseId: String) -> String {
        "dropImages/\(userId)/\(responseId).jpg"
    }
}

// MARK: - Drop Mechanic Config
enum DropConfig {
    static let windowDurationSeconds: TimeInterval = 5 * 60   // 5-min capture window
    static let gracePeriodSeconds: TimeInterval    = 30 * 60  // 30-min late window
    static let feedExpiryDays: Int                 = 7
    static let maxCaptionLength: Int               = 150
    static let imageCompressionQuality: CGFloat    = 0.72
}

// MARK: - Streak Config
enum StreakConfig {
    // On-time = submitted within the active window
    // Late = submitted within the grace period (counts toward feed unlock, NOT streak)
    static let onTimeThreshold = "onTime"
    static let lateThreshold   = "late"
    static let missedThreshold = "missed"
}

// MARK: - Badge Identifiers
enum BadgeID: String, CaseIterable {
    case dropKing         = "drop_king"
    case alwaysOnTime     = "always_on_time"
    case chaosAgent       = "chaos_agent"
    case weekWarrior      = "week_warrior"
    case nightOwl         = "night_owl"
    case streakStarter    = "streak_starter"
    case ghostMode        = "ghost_mode"
    case lateMerchant     = "late_merchant"
    case consistentGrind  = "consistent_grind"
    case firstDrop        = "first_drop"

    var displayName: String {
        switch self {
        case .dropKing:        return "Drop King"
        case .alwaysOnTime:    return "Always On Time"
        case .chaosAgent:      return "Chaos Agent"
        case .weekWarrior:     return "Week Warrior"
        case .nightOwl:        return "Night Owl"
        case .streakStarter:   return "Streak Starter"
        case .ghostMode:       return "Ghost Mode"
        case .lateMerchant:    return "Late Merchant"
        case .consistentGrind: return "Consistent Grinder"
        case .firstDrop:       return "First Drop"
        }
    }

    var emoji: String {
        switch self {
        case .dropKing:        return "👑"
        case .alwaysOnTime:    return "⚡️"
        case .chaosAgent:      return "🌀"
        case .weekWarrior:     return "🏆"
        case .nightOwl:        return "🦉"
        case .streakStarter:   return "🔥"
        case .ghostMode:       return "👻"
        case .lateMerchant:    return "🕰️"
        case .consistentGrind: return "💪"
        case .firstDrop:       return "🎯"
        }
    }
}

// MARK: - Current Vibe Options
enum VibeOption: String, CaseIterable, Identifiable {
    case caffeine      = "running on caffeine"
    case libraryPrison = "library prisoner"
    case mainCharacter = "main character"
    case chaoticNeutral = "chaotic neutral"
    case gymArc        = "gym arc"
    case deadlineMode  = "deadline mode"
    case procrastinationMode = "procrastination mode"
    case unbothered    = "unbothered"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .caffeine:          return "☕️"
        case .libraryPrison:     return "📚"
        case .mainCharacter:     return "🎬"
        case .chaoticNeutral:    return "🌀"
        case .gymArc:            return "🏋️"
        case .deadlineMode:      return "⏰"
        case .procrastinationMode: return "😅"
        case .unbothered:        return "😎"
        }
    }
}

// MARK: - Vibe Tag Options (for Drop submissions)
enum VibeTag: String, CaseIterable, Identifiable {
    case grinding  = "Grinding"
    case social    = "Social"
    case gym       = "Gym"
    case chaos     = "Chaos"
    case quiet     = "Quiet"
    case outAbout  = "Out & About"
    case nightEnergy = "Night Energy"
    case vibing    = "Vibing"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .grinding:    return "📚"
        case .social:      return "🗣️"
        case .gym:         return "💪"
        case .chaos:       return "🌪️"
        case .quiet:       return "🤫"
        case .outAbout:    return "🚶"
        case .nightEnergy: return "🌙"
        case .vibing:      return "✨"
        }
    }
}

// MARK: - Campus Zone Types
enum ZoneType: String, CaseIterable, Identifiable {
    case library       = "Library"
    case cafe          = "Cafe"
    case gym           = "Gym"
    case lab           = "Lab"
    case dorm          = "Dorm"
    case campusCenter  = "Campus Center"
    case offCampus     = "Off Campus"
    case other         = "Other"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .library:      return "📚"
        case .cafe:         return "☕️"
        case .gym:          return "🏋️"
        case .lab:          return "🔬"
        case .dorm:         return "🏠"
        case .campusCenter: return "🏛️"
        case .offCampus:    return "🌆"
        case .other:        return "📍"
        }
    }
}

// MARK: - Drop Prompts (used for MVP seeding)
enum DropPrompts {
    static let all: [(title: String, prompt: String, icon: String)] = [
        ("Show Up", "Show what's in front of you right now", "📸"),
        ("Current Chaos", "Show your current chaos", "🌪️"),
        ("Who's With You", "Show who you're with right now", "👥"),
        ("Drop Your Desk", "Drop your workspace, no filter", "🖥️"),
        ("Drop Your Shoes", "Drop your shoes — no excuses", "👟"),
        ("Face Right Now", "Drop your face right now. No filter.", "🫵"),
        ("Study Setup", "Show your study setup", "📚"),
        ("Current Vibe", "Show your current vibe in one shot", "✨"),
        ("The View", "Drop the view from where you are", "🏙️"),
        ("What You're Eating", "Show what you're eating rn", "🍔"),
        ("Your Fit", "Drop your fit today", "👔"),
        ("The Energy", "Capture the energy around you", "⚡️"),
    ]
}
