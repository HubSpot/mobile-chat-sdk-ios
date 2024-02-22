// DeviceTokenSyncState.swift
// Hubspot Mobile SDK
//
// Copyright © 2024 Hubspot, Inc.

import Foundation

/// Enum to help track if we have posted our device token, and when
enum DeviceTokenSyncState: Equatable {
    case notSent
    case sending(Date)
    case sent(Date)
}
