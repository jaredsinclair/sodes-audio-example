//
//  EpisodeDuration.swift
//  Sodes
//
//  Created by Jared Sinclair on 8/28/16.
//
//

import Foundation

public struct EpisodeDurationParsing {
    
    private static let lock = NSLock()
    private static let calendar = Calendar(identifier: .gregorian)
    
    private static let hourMinuteSecondFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    private static let minuteSecondFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss"
        return formatter
    }()
    
    public static func duration(from string: String) -> TimeInterval? {
        
        let comps = string.components(separatedBy: ":").filter{!$0.isEmpty}
        
        guard !comps.isEmpty else {return nil}
        
        let duration: TimeInterval
        
        if comps.count == 1 && string.range(of: ":") == nil {
            duration = comps[0].toSeconds(constrainToClockRange: false)
        }
        else if comps.count == 2 {
            guard comps[0].characters.count == 2 else {return nil}
            guard comps[1].characters.count == 2 else {return nil}
            duration =
                  comps[0].toMinutes() * 60
                + comps[1].toSeconds(constrainToClockRange: true)
        }
        else if comps.count == 3 {
            guard comps[1].characters.count == 2 else {return nil}
            guard comps[2].characters.count == 2 else {return nil}
            duration =
                  comps[0].toHours() * 3600
                + comps[1].toMinutes() * 60
                + comps[2].toSeconds(constrainToClockRange: true)
        }
        else {
            duration = 0
        }
        
        return (duration > 0) ? duration : nil
        
    }
    
    public static func string(from duration: TimeInterval) -> String {
        
        guard duration > 0 else {return "00:00"}
        guard duration <= (23*3600 + 59*60 + 59) else {return "23:59:59"}
        
        let hours = floor(duration / 3600)
        let minutesAndSeconds = duration.truncatingRemainder(dividingBy: 3600)
        let minutes = floor(minutesAndSeconds / 60)
        let seconds = floor(minutesAndSeconds.truncatingRemainder(dividingBy: 60))
        
        var comps = DateComponents()
        comps.calendar = calendar
        comps.day = 1
        comps.month = 1
        comps.year = 2016
        comps.hour = Int(hours)
        comps.minute = Int(minutes)
        comps.second = Int(seconds)
        
        guard let date = comps.date else {return "00:00"}
        
        if hours > 0 {
            lock.lock()
            let result = hourMinuteSecondFormatter.string(from: date)
            lock.unlock()
            return result
        } else {
            lock.lock()
            let result = minuteSecondFormatter.string(from: date)
            lock.unlock()
            return result
        }
        
    }
    
    private init() {}
    
}

private extension String {
    
    func toSeconds(constrainToClockRange: Bool) -> TimeInterval {
        guard let possible = TimeInterval(self) else {return 0}
        if (constrainToClockRange) {
            return (0 <= possible && possible <= 59) ? possible : 0
        } else {
            return possible
        }
    }
    
    func toMinutes() -> TimeInterval {
        guard let possible = TimeInterval(self) else {return 0}
        return (0 <= possible && possible <= 59) ? possible : 0
    }
    
    func toHours() -> TimeInterval {
        return TimeInterval(self) ?? 0
    }
    
}

private func *(lhs: TimeInterval?, rhs: TimeInterval) -> TimeInterval {
    return (lhs ?? 0) * rhs
}
