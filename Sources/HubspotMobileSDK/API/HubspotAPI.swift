// HubspotAPI.swift
// Hubspot Mobile SDK
//
// Copyright © 2024 Hubspot, Inc.

import Foundation
import OSLog

/// Not public class yet, as its not known if we need to expose API directly to app.
class HubspotAPI {
    var logger: Logger

    init(logger: Logger) {
        self.logger = logger
    }

    /// Errors relating to API requests and reponses that the SDK may make.
    enum APIError: Error {
        /// Unable to form a request - likely due to poor configuration or formatting
        case requestError

        /// Response couldn't be handled as expected, perhaps due to decoding error or similar. Original error included.
        case responseError(Error)
    }

    private let jsonEncoder: JSONEncoder = .init()
    private let jsonDecoder: JSONDecoder = .init()

    private let urlSession = URLSession(configuration: .default)
    private let baseUrl = URL(string: "https://api.hubapi.com/")!

    func sendDeviceToken(token: Data, portalId: String) async throws {
        // POST

        let apiUrl = baseUrl.appendingPathComponent("livechat-public/v1/mobile-sdk/device-token")

        guard var components = URLComponents(url: apiUrl, resolvingAgainstBaseURL: false) else {
            throw APIError.requestError
        }

        components.queryItems = [URLQueryItem(name: "portalId", value: portalId)]

        guard let url = components.url else {
            throw APIError.requestError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let postBodyModel = StoreDeviceTokenRequest(devicePushToken: token)
        let requestData = try jsonEncoder.encode(postBodyModel)

        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData

        let (data, _) = try await urlSession.data(for: request)

        #if DEBUG
            // Right now , we aren't using the reponse, but just logging it temporiarly to see if we get a response - I expect this to change once the api gets integrated in server, then we can either use the response or ignore it.
            let bodyString = String(data: data, encoding: .utf8)
            logger.trace("Response from sending token: \(bodyString ?? "<EMPTY>")")
        #endif
    }

    func deleteDeviceToken(token: Data, portalId: String) async throws {
        // DELETE
        let apiUrl = baseUrl.appendingPathComponent("livechat-public/v1/mobile-sdk/device-token/\(token.toHexString())")

        guard var components = URLComponents(url: apiUrl, resolvingAgainstBaseURL: false) else {
            throw APIError.requestError
        }

        components.queryItems = [URLQueryItem(name: "portalId", value: portalId)]

        guard let url = components.url else {
            throw APIError.requestError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (data, _) = try await urlSession.data(for: request)

        #if DEBUG
            // Right now , we aren't using the reponse, but just logging it temporiarly to see if we get a response - I expect this to change once the api gets integrated in server, then we can either use the response or ignore it.
            let bodyString = String(data: data, encoding: .utf8)
            logger.trace("Response from deleting token: \(bodyString ?? "<EMPTY>")")
        #endif
    }

    /// Post chat properties for a specific thread id to the api.
    /// - Parameters:
    ///   - properties: The collection of properties to post.
    ///   - visitorIdToken: The token set by the app to identify user. Optional.
    ///   - threadId: The thread id read from the chat view / javascript bridge that identifies the current open thread
    ///   - portalId: Account portal id
    func sendChatProperties(properties: [String: String], visitorIdToken: String?, email: String?, threadId: String, portalId: String) async throws {
        let urlProperties = ["portalId": portalId, "threadId": threadId]

        let apiUrl = baseUrl.appendingPathComponent("livechat-public/v1/mobile-sdk/metadata")
        guard var urlBuilder = URLComponents(url: apiUrl, resolvingAgainstBaseURL: false) else {
            throw APIError.requestError
        }

        urlBuilder.queryItems = urlProperties.map { key, value in URLQueryItem(name: key, value: value) }

        guard let url = urlBuilder.url else {
            throw APIError.requestError
        }

        let requestModel = ChatPropertyMetadataRequest(visitorToken: visitorIdToken, email: email, metadata: properties)
        let requestData = try jsonEncoder.encode(requestModel)

        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"

        request.httpBody = requestData
        let (_, response) = try await urlSession.data(for: request)


        if let httpResponse = response as? HTTPURLResponse {
            // We aren't expecting any content as a response, just that it succeeded - hopefully the try await above is sufficient.
            // Logging the code in debug builds just to confirm for now
            #if DEBUG
                if case 200 ..< 300 = httpResponse.statusCode {
                    logger.trace("Sending metadata was a 2XX response: \(httpResponse.statusCode)")
                }
            #endif
        }
    }

    /// Convenience for creating a visitor identity token using the given details, for situations where server infrastructure isn't available.
    ///
    ///  - WARNING: Embedding access token for your product in app is not recommended - This was originally for demo purposes, and may be removed. Strongly consider creating a token as part of app server infrastructure instead.
    ///
    /// - Parameters:
    ///   - accessToken: The access token for your application, as returned by the Hubspot dashboard
    ///   - email: the email of the user
    ///   - firstName: users first name
    ///   - lastName: users last name
    /// - Returns: The generated JWT token
    func createVisitorToken(accessToken: String, email: String, firstName: String, lastName: String) async throws -> String {
        // Later, if we have lots of requests we can refactor this to have common base path
        let url = baseUrl.appendingPathComponent("conversations/v3/visitor-identification/tokens/create")

        let requestModel = CreateVisitorTokenRequest(email: email, firstName: firstName, lastName: lastName)
        let requestData = try jsonEncoder.encode(requestModel)

        var request = URLRequest(url: url)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"

        request.httpBody = requestData

        let (data, response) = try await urlSession.data(for: request)

        do {
            let responseModel = try jsonDecoder.decode(CreateVisitorTokenResponse.self, from: data)
            return responseModel.token
        } catch {
            let bodyString = String(data: data, encoding: .utf8)
            /// Catching just to log, and then re-throw it wrapped
            logger.error("Failed to decode visitor token model: \(error) - response was \(response), body contents: \(bodyString ?? "not set")")
            throw APIError.responseError(error)
        }
    }
}
