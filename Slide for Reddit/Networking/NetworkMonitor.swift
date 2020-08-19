//
//  NetworkMonitor.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 8/16/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Foundation
import Network

final class NetworkMonitor {
    // MARK: - References / Properties
    /// Refers to NetworkMonitor class once throughout application.
    public static let shared = NetworkMonitor()
    /// Accesses Network Path Monitor.
    private var pathMonitor: NWPathMonitor?
    /**
     Types of Interfaces the User could be connected with.
     - Wi-Fi: Uses Wi-Fi as a connection source.
     - Cellular: Uses Cellular as a connection source.
     - WiredEthernet: Uses Wired Ethernet as a connection source. Not Applicable.
     - Loopback: Uses local Loopback Networks as a connection source.
     - Other: Uses Virtual Networks or Unknown Types as a connection source.
     */
    var interfaceType: NWInterface.InterfaceType? {
        guard let pathMonitor = pathMonitor else { return nil }
        return pathMonitor.currentPath.availableInterfaces.filter({
            pathMonitor.currentPath.usesInterfaceType( $0.type )
        }).first?.type
    }
    /// Name of the Network Interface.
    public var interfaceName: String? {
        guard let pathMonitor = pathMonitor else { return nil }
        return pathMonitor.currentPath.availableInterfaces.map({ $0.name }).first
    }
    /// Full description of Network Interface.
    public var networkInterfaceDescription: String? {
        guard let pathMonitor = pathMonitor else { return nil }
        return pathMonitor.currentPath.availableInterfaces.map({ $0.debugDescription }).first
    }
    /// Checks if the current Network is Online.
    public var online: Bool {
        guard let pathMonitor = pathMonitor else { return false }
        return pathMonitor.currentPath.status == .satisfied
    }
    /// Checks if the User has an Interface in Low Data Mode.
    @available(iOS 13.0, *)
    public var isInterfaceConstrained: Bool? {
        guard let pathMonitor = pathMonitor else { return nil }
        return pathMonitor.currentPath.isConstrained
    }
    /// Checks if interface is connected to an expensive source, such as Cellular or Personal Hotspot.
    public var isInterfaceExpensive: Bool? {
        guard let pathMonitor = pathMonitor else { return nil }
        return pathMonitor.currentPath.isExpensive
    }
    /// Used to check if pathMonitor is currently Monitoring.
    private var isPathMonitoring: Bool = false
    /// Monitoring Queue used for start monitoring Network.
    private let networkQueue = DispatchQueue(label: "NetworkMonitorQueue", qos: .background)
    // MARK: Network Handlers
    /**
     Handler starting the monitoring of the Network.
     - Make any updates after the Monitoring started.
     */
    public var startedMonitoringNetwork: (() -> Void)?
    /**
     Handler stopping Network monitoring.
     - Make any updates to the User alerting them that the Monitoring Stopped.
     */
    public var stoppedMonitoringNetwork: (() -> Void)?
    /**
     Handler called every time the Network changes.
     - Use when a view is being created, do any additional changes inside to update the view of any changes that occur.
     */
    public var networkStatusDidChange: (() -> Void)?
    
    private init() {
    }
    
    deinit {
        stopNetworkMonitoring()
    }
    
    // MARK: - Public Methods
    /**
     Starts monitoring of Network.
     - Usually called once in App Delegate.
     */
    public func startNetworkMonitoring() {
        // Checks if Monitor is already Monitoring.
        guard !isPathMonitoring else { return }
        // Initializes Path Monitor.
        pathMonitor = NWPathMonitor()
        // Starts the Monitoring of Network on a separate Queue.
        pathMonitor?.start(queue: networkQueue)
        // Handler which updates anytime changes happen with Network.
        pathMonitor?.pathUpdateHandler = { [weak self] path in
            // Calls property handler for any changes made to Network.
            self?.networkStatusDidChange?()
        }
        // Sets monitoring to True.
        isPathMonitoring = true
        // Tells the handler it started monitoring.
        startedMonitoringNetwork?()
    }
    
    /**
     Stops monitoring of Network if already running.
     - Usually called to stop monitoring as checking for network changes constantly could take up Users battery life rather quickly.
     */
    public func stopNetworkMonitoring() {
        // Checks to see if Monitoring isn't enabled and Path Monitor isn't Initialized.
        guard isPathMonitoring, let pathMonitor = pathMonitor else { return }
        // Stops Network Monitoring
        pathMonitor.cancel()
        // Set's Path Monitor to Nil.
        self.pathMonitor = nil
        // Set's local Monitoring Bool to false.
        isPathMonitoring = false
    }
    
}
