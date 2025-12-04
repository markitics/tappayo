//  BluetoothPermissionManager.swift
//  Tappayo

import CoreBluetooth
import Combine

class BluetoothPermissionManager: NSObject, ObservableObject {
    @Published var authorizationStatus: CBManagerAuthorization

    private var centralManager: CBCentralManager?

    override init() {
        self.authorizationStatus = CBCentralManager.authorization
        super.init()
    }

    func requestPermission() {
        // Creating CBCentralManager triggers the permission prompt if not determined
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
    }

    var statusText: String {
        switch authorizationStatus {
        case .allowedAlways:
            return "Granted"
        case .denied, .restricted:
            return "Denied"
        case .notDetermined:
            return "Not Set"
        @unknown default:
            return "Unknown"
        }
    }

    var isGranted: Bool {
        authorizationStatus == .allowedAlways
    }
}

extension BluetoothPermissionManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = CBCentralManager.authorization
        }
    }
}
