//
//  PlaceAnnotation.swift
//  d2d-crm-desktop
//
//  Created by Emin Okic on 6/8/25.
//


import Foundation
import MapKit
import SwiftUI

struct PlaceAnnotation: Identifiable {
    let id = UUID()
    let address: String
    let location: CLLocationCoordinate2D
    let markerColor: Color
}
