//
//  PermissionService.swift
//  Random Pro
//
//  Created by Vitalii Sosin on 26.08.2022.
//  Copyright © 2022 SosinVitalii.com. All rights reserved.
//

import UIKit
import AppTrackingTransparency
import Photos

public protocol PermissionService {
  
  /// Запрос на отслеживание. Доступно с IOS 14
  ///  - Parameter status: Статус ответа пользователя
  @available(iOS 14, *)
  func requestIDFA(_ status: ((ATTrackingManager.AuthorizationStatus) -> Void)?)
  
  /// Запрос доступа к Галерее
  ///  - Parameter granted: Доступ разрешен
  func requestPhotos(_ status: ((_ granted: Bool) -> Void)?)
  
  /// Запрос доступа к Уведомлениям
  ///  - Parameter granted: Доступ разрешен
  func requestNotification(_ granted: @escaping (Bool) -> Void)
  
  /// Получить статус уведомлений
  ///  - Parameter granted: Доступ разрешен
  func getNotification(status: @escaping (UNAuthorizationStatus) -> Void)
}

public final class PermissionServiceImpl: PermissionService {
  public init() {}
  
  public func getNotification(status: @escaping (UNAuthorizationStatus) -> Void) {
    let center = UNUserNotificationCenter.current()
    center.getNotificationSettings { settings in
      DispatchQueue.main.async {
        status(settings.authorizationStatus)
      }
    }
  }
  
  public func requestNotification(_ granted: @escaping (Bool) -> Void) {
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .sound, .badge]) { result, _ in
      DispatchQueue.main.async {
        granted(result)
        guard result else { return }
        UIApplication.shared.registerForRemoteNotifications()
      }
    }
  }
  
  @available(iOS 14, *)
  public func requestIDFA(_ status: ((ATTrackingManager.AuthorizationStatus) -> Void)? = nil) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      switch ATTrackingManager.trackingAuthorizationStatus {
      case .notDetermined:
        status?(.notDetermined)
        ATTrackingManager.requestTrackingAuthorization(completionHandler: { _ in })
      case .restricted:
        status?(.restricted)
      case .denied:
        status?(.denied)
      case .authorized:
        status?(.authorized)
      @unknown default: break
      }
    }
  }
  
  public func requestPhotos(_ status: ((_ granted: Bool) -> Void)?) {
    if #available(iOS 14, *) {
      PHPhotoLibrary.requestAuthorization(for: .readWrite) { (resultStatus) in
        DispatchQueue.main.async {
          switch resultStatus {
          case .denied, .notDetermined, .restricted:
            status?(false)
          case .authorized, .limited:
            status?(true)
          @unknown default:
            status?(false)
          }
        }
      }
    } else {
      PHPhotoLibrary.requestAuthorization({ resultStatus in
        DispatchQueue.main.async {
          switch resultStatus {
          case .denied, .notDetermined, .restricted:
            status?(false)
          case .authorized, .limited:
            status?(true)
          @unknown default:
            status?(false)
          }
        }
      })
    }
  }
}
