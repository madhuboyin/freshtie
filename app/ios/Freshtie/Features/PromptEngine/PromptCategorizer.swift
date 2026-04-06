import Foundation

/// Maps extracted text signals to a PromptCategory.
/// Checked in priority order — more specific categories beat broader ones.
enum PromptCategorizer {

    static func categorize(signals: TextSignals) -> PromptCategory {
        let t = signals.tokens
        // Life events are specific and high-value — check first
        if !t.isDisjoint(with: lifeEventKeywords) { return .lifeEvent  }
        if !t.isDisjoint(with: moveKeywords)       { return .move       }
        if !t.isDisjoint(with: travelKeywords)     { return .travel     }
        if !t.isDisjoint(with: professionalKeywords){ return .professional }
        if !t.isDisjoint(with: familyKeywords)     { return .family     }
        if !t.isDisjoint(with: healthKeywords)     { return .health     }
        if !t.isDisjoint(with: schoolKeywords)     { return .school     }
        return .generic
    }

    // MARK: - Keyword sets

    private static let lifeEventKeywords: Set<String> = [
        "wedding","married","marriage","engaged","engagement","divorce",
        "baby","pregnant","pregnancy","birth","born","newborn",
        "graduation","graduated","funeral","passed","died","passing",
        "anniversary","retirement","retired","ceremony","proposal","expecting",
    ]

    private static let moveKeywords: Set<String> = [
        "moving","moved","move","relocating","relocation","relocate",
        "apartment","renting","lease","landlord","packing","packed","unpacking",
        "bought","buying","townhouse","condo","neighborhood","neighbourhood",
    ]

    private static let travelKeywords: Set<String> = [
        "trip","travel","traveling","travelling","flight","flew","flying",
        "vacation","holiday","abroad","visiting","visit","airport","hotel",
        "tour","cruise","backpacking","roadtrip","passport","visa","jetlag",
    ]

    private static let professionalKeywords: Set<String> = [
        "job","work","career","office","company","hired","hire","fired",
        "interview","promotion","promoted","role","position","colleague",
        "boss","manager","team","startup","business","employment","working",
        "onboarding","layoff","laid","quit","resigned","resignation","freelance",
        "client","contract","raise","salary","remote","offer",
    ]

    private static let familyKeywords: Set<String> = [
        "family","kids","kid","children","child","daughter","son",
        "parents","parent","mom","dad","mother","father","sister",
        "brother","grandma","grandpa","grandmother","grandfather",
        "aunt","uncle","cousin","wife","husband","spouse","partner",
        "siblings","sibling","nephew","niece","in-laws","inlaws",
    ]

    private static let healthKeywords: Set<String> = [
        "surgery","hospital","sick","doctor","medical","health",
        "recovery","recovering","injury","injured","ill","illness",
        "diagnosis","diagnosed","operation","therapy","treatment",
        "pain","medication","prescription","appointment","rehab","healing",
    ]

    private static let schoolKeywords: Set<String> = [
        "school","college","university","exam","exams","finals","test",
        "studying","study","degree","class","classes","semester",
        "graduate","thesis","dissertation","tuition","campus","coursework",
    ]
}
