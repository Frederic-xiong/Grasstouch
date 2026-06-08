import Foundation
import CoreData

/// Persists `MetricSample` rows from the kbps figures the tunnel publishes.
/// Called by the main app on a timer while a tunnel session is active.
struct MetricsCollector {
    let context: NSManagedObjectContext

    func recordSample(sessionID: UUID, kbpsDown: Double, kbpsUp: Double) {
        context.perform {
            let sample = MetricSample(context: context)
            sample.id = UUID()
            sample.timestamp = Date()
            sample.kbpsDown = kbpsDown
            sample.kbpsUp = kbpsUp

            let req: NSFetchRequest<ThrottleSession> = ThrottleSession.fetchRequest()
            req.predicate = NSPredicate(format: "id == %@", sessionID as CVarArg)
            req.fetchLimit = 1
            sample.session = try? context.fetch(req).first

            try? context.save()
        }
    }

    func startSession(level: ThrottleLevel) -> UUID {
        let id = UUID()
        context.performAndWait {
            let session = ThrottleSession(context: context)
            session.id = id
            session.startedAt = Date()
            session.level = Int16(level.rawValue)
            session.bytesThrottled = 0
            try? context.save()
        }
        return id
    }

    func endSession(_ id: UUID) {
        context.perform {
            let req: NSFetchRequest<ThrottleSession> = ThrottleSession.fetchRequest()
            req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            req.fetchLimit = 1
            guard let session = try? context.fetch(req).first else { return }
            session.endedAt = Date()
            try? context.save()
        }
    }
}
