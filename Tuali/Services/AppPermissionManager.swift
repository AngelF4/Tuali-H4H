import AVFoundation
import CoreLocation
import Observation
import UserNotifications

@MainActor
@Observable
final class AppPermissionManager: NSObject, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
    private let locationManager = CLLocationManager()
    private var didRequestPermissions = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestAll() async {
        guard !didRequestPermissions else { return }
        didRequestPermissions = true
        
        if CLLocationManager().authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            _ = await AVCaptureDevice.requestAccess(for: .video)
        }
        
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        )
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {}
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }
}
