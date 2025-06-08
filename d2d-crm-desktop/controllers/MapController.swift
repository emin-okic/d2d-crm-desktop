//
//  MapController.swift
//  d2d-map-service
//
//  Created by Emin Okic on 5/31/25.
//

import Foundation
import MapKit
import CoreLocation

/// `MapController` manages map-related logic such as marker placement, geocoding searches,
/// and updating the visible map region based on annotations.
///
/// This class supports:
/// - Managing a list of `IdentifiablePlace` markers
/// - Performing geocoded address searches
/// - Centering and zooming the map to fit all markers
/// - Dynamically updating markers based on prospects
class MapController: ObservableObject {
    
    /// Published list of markers (used in SwiftUI map annotations)
    @Published var markers: [IdentifiablePlace] = []

    /// Current visible region of the map
    @Published var region: MKCoordinateRegion
    
    /// Initializes the controller with a given map region.
    init(region: MKCoordinateRegion) {
        self.region = region
    }
    
    /// Clears all existing markers from the map.
    func clearMarkers() {
        markers.removeAll()
    }

    /// Normalizes a string (e.g. address) for comparison (lowercased and trimmed).
    private func normalized(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    /// Performs a geocoding search on the provided address and places or updates a marker on the map.
    /// - Parameter query: The address string to geocode.
    func performSearch(query: String) {
        let key = normalized(query)
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(query) { [weak self] placemarks, error in
            guard let self = self else { return }
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                return
            }
            
            DispatchQueue.main.async {
                if let existingIndex = self.markers.firstIndex(where: { self.normalized($0.address) == key }) {
                    self.markers[existingIndex].count += 1
                } else {
                    let newPlace = IdentifiablePlace(
                        address: query,
                        location: location.coordinate,
                        count: 1
                    )
                    self.markers.append(newPlace)
                }
                self.updateRegionToFitAllMarkers()
            }
        }
    }
    
    /// Updates the `region` property to fit all current markers on the map.
    private func updateRegionToFitAllMarkers() {
        guard !markers.isEmpty else { return }

        let latitudes = markers.map { $0.location.latitude }
        let longitudes = markers.map { $0.location.longitude }

        let minLat = latitudes.min()!
        let maxLat = latitudes.max()!
        let minLon = longitudes.min()!
        let maxLon = longitudes.max()!

        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2

        let latDelta = (maxLat - minLat) * 1.5
        let lonDelta = (maxLon - minLon) * 1.5

        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: max(latDelta, 0.01),
                                   longitudeDelta: max(lonDelta, 0.01))
        )
    }
    
    /// Geocodes and adds map markers for the given list of prospects.
    /// - Parameter prospects: Array of `Prospect` objects.
    func addProspects(_ prospects: [Prospect]) {
        for prospect in prospects {
            performSearch(query: prospect.address)
        }
    }
    
    /// Replaces existing markers with those derived from the provided list of prospects.
    /// - Parameter prospects: Array of `Prospect` objects to display.
    func setMarkers(for prospects: [Prospect]) {
        clearMarkers()
        
        for prospect in prospects {
            let address = prospect.address
            let geocoder = CLGeocoder()
            
            geocoder.geocodeAddressString(address) { [weak self] placemarks, error in
                guard let self = self else { return }
                guard let placemark = placemarks?.first,
                      let location = placemark.location else {
                    return
                }
                
                DispatchQueue.main.async {
                    let newPlace = IdentifiablePlace(
                        address: address,
                        location: location.coordinate,
                        count: prospect.count
                    )
                    self.markers.append(newPlace)
                    self.updateRegionToFitAllMarkers()
                }
            }
        }
    }
}
