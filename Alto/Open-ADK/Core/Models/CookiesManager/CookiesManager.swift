//
//  CookiesManager.swift
//  Beam
//
//  Created by Ludovic Ollagnier on 06/04/2022.
//

import Foundation
import WebKit


/// Used to inject cookies into the WKWebsiteDataStore
///
/// This code is directly pulled from Beam:
/// https://github.com/beamlegacy/beam/blob/3fa234d6ad509c2755c16fb3fd240e9142eaa8bb/Beam/Classes/Models/CookiesManager.swift#L11
final class CookiesManager: NSObject, WKHTTPCookieStoreObserver {

    let cookieStorage: HTTPCookieStorage

    override init() {
        cookieStorage = HTTPCookieStorage()
    }

    func setupCookies(for webView: WKWebView) {
        let configuration = webView.configurationWithoutMakingCopy
        for cookie in cookieStorage.cookies ?? [] {
            configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
        }

        configuration.websiteDataStore.httpCookieStore.add(self)
    }

    public func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
        cookieStore.getAllCookies({ [weak self] cookies in
            guard let self = self else { return }

            for cookie in cookies {
                self.cookieStorage.setCookie(cookie)
            }
        })
    }

    public func clearCookiesAndCache() {
        cookieStorage.cookies?.forEach(cookieStorage.deleteCookie)

        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), completionHandler: { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        })
    }
}
