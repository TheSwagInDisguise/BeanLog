import Foundation
import CoreLocation

/// One-shot "where am I" lookup: CoreLocation fix + reverse geocode to a suburb name.
final class LocationService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    struct Place {
        var name: String
        var coordinate: CLLocationCoordinate2D
    }

    enum LocationError: LocalizedError {
        case denied
        case notFound
        var errorDescription: String? {
            switch self {
            case .denied: return "Location access is off. You can enable it for BeanLog in Settings, or type the suburb."
            case .notFound: return "Couldn't work out the suburb here. Try typing it instead."
            }
        }
    }

    private let manager = CLLocationManager()
    private var authContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    @MainActor
    func currentPlace() async throws -> Place {
        var status = manager.authorizationStatus
        if status == .notDetermined {
            status = await withCheckedContinuation { (cont: CheckedContinuation<CLAuthorizationStatus, Never>) in
                authContinuation = cont
                manager.requestWhenInUseAuthorization()
            }
        }
        guard status == .authorizedWhenInUse || status == .authorizedAlways else { throw LocationError.denied }

        let location = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<CLLocation, Error>) in
            locationContinuation = cont
            manager.requestLocation()
        }
        let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
        guard let mark = placemarks.first else { throw LocationError.notFound }
        let area = mark.subLocality ?? mark.locality ?? mark.name
        guard let area else { throw LocationError.notFound }
        let name = [area, mark.administrativeArea].compactMap { $0 }.joined(separator: ", ")
        return Place(name: name, coordinate: location.coordinate)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        guard status != .notDetermined, let cont = authContinuation else { return }
        authContinuation = nil
        cont.resume(returning: status)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last, let cont = locationContinuation else { return }
        locationContinuation = nil
        cont.resume(returning: loc)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard let cont = locationContinuation else { return }
        locationContinuation = nil
        cont.resume(throwing: error)
    }
}
