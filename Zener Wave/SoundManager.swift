// SoundManager.swift
// Lightweight sound effects using iOS system sounds

import AudioToolbox

enum SoundManager {
    /// Short positive chime for a correct guess
    static func playCorrect() {
        AudioServicesPlaySystemSound(1025)
    }

    /// Short low tone for an incorrect guess
    static func playIncorrect() {
        AudioServicesPlaySystemSound(1053)
    }
}
