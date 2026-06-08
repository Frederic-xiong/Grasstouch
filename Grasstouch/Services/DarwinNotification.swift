import Foundation

/// Thin wrapper over `CFNotificationCenterGetDarwinNotifyCenter`. Darwin
/// notifications are the only reliable IPC between the main app, the packet
/// tunnel extension, and the DeviceActivity monitor extension.
enum DarwinNotification {
    static func post(_ name: CFString) {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(
            center,
            CFNotificationName(name),
            nil, nil, true
        )
    }
}

final class DarwinNotificationObserver {
    private let name: CFString
    private let handler: () -> Void
    private var token: UnsafeMutableRawPointer?

    init(name: CFString, handler: @escaping () -> Void) {
        self.name = name
        self.handler = handler

        let observer = Unmanaged.passUnretained(self).toOpaque()
        self.token = observer
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterAddObserver(
            center,
            observer,
            { _, observer, _, _, _ in
                guard let observer = observer else { return }
                let me = Unmanaged<DarwinNotificationObserver>.fromOpaque(observer).takeUnretainedValue()
                me.handler()
            },
            name,
            nil,
            .deliverImmediately
        )
    }

    deinit {
        if let token = token {
            CFNotificationCenterRemoveObserver(
                CFNotificationCenterGetDarwinNotifyCenter(),
                token,
                CFNotificationName(name),
                nil
            )
        }
    }
}
