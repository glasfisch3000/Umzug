//
//  ContentView.swift
//  Umzug
//
//  Created by Jakob Danckwerts on 20.11.24.
//

import SwiftUI
import APIInterface

struct ContentView: View {
    enum TabSelection: String, Hashable {
        case boxes
    }
    
    @AppStorage("hostname") private var hostname = ""
    @AppStorage("port") private var port: UInt16 = 443
    @State private var username = ""
    @State private var password = ""
    
    @AppStorage("tab-selection") private var tabSelection: TabSelection = .boxes
    
    @State private var api: UmzugAPI? = nil
    
    var body: some View {
        if let api = api {
            switch api.status {
            case .normal: apiView(api)
            case .error(.invalidAuthentication): loginView(invalidAuthentication: true)
            case .error(let error): errorView(error)
            }
        } else {
            loginView()
        }
    }
    
    @ViewBuilder
    private func apiView(_ api: UmzugAPI) -> some View {
        BoxesView(boxes: api.fetched(for: .boxes))
    }
    
    @ViewBuilder
    private func errorView(_ error: UmzugAPI.APIError) -> some View {
        VStack(alignment: .center) {
            Spacer()
            
            Image(systemName: "exclamationmark.octagon.fill")
                .symbolRenderingMode(.multicolor)
                .font(.largeTitle)
            
            Text("An error occurred while connecting to the API.")
            
            Group {
                switch error {
                case .invalidURL: Text("Invalid URL")
                case .invalidAuthentication: Text("Invalid authentication")
                case .clientShutdown: Text("Client shutdown")
                case .invalidStatus(let status): Text("Invalid HTTP response status: \(status)")
                case .other: Text("Unknown error")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            Spacer()
            
            Button {
                self.api = nil
            } label: {
                HStack {
                    Spacer()
                    
                    Text("Disconnect")
                    
                    Spacer()
                }
            }
            .buttonBorderShape(.roundedRectangle)
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    @ViewBuilder
    private func loginView(invalidAuthentication: Bool = false) -> some View {
        Form {
            VStack(spacing: 30) {
                Spacer()
                
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.octagon.fill")
                        .symbolRenderingMode(.multicolor)
                        .font(.largeTitle)
                    
                    Text("Invalid authentication.")
                        .font(.headline)
                }
                
                Spacer()
                
                VStack {
                    Section {
                        HStack {
                            TextField("hostname", text: $hostname)
                            
                            Text(":")
                                .opacity(0.8)
                            
                            TextField("port", value: $port, format: .number.sign(strategy: .never).grouping(.never))
                                .keyboardType(.numberPad)
                                .frame(maxWidth: 70)
                        }
                        .styleLoginViewTextfield()
                    } header: {
                        Text("Server")
                            .styleLoginViewSectionHeader()
                    }
                }
                
                VStack {
                    Section {
                        TextField("username", text: $username)
                            .textContentType(.username)
                            .styleLoginViewTextfield()
                        
                        SecureField("password", text: $password)
                            .textContentType(.password)
                            .styleLoginViewTextfield()
                    } header: {
                        Text("Login Credentials")
                            .styleLoginViewSectionHeader()
                    }
                }
                
                Spacer()
                Spacer()
                
                Button {
                    self.authenticate(storeCredentials: true)
                } label: {
                    Text("Log In")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.defaultAction)
                .buttonBorderShape(.roundedRectangle)
                .buttonStyle(.borderedProminent)
                .font(.title2)
                .disabled(hostname.isEmpty)
                .disabled(username.isEmpty)
                .disabled(password.isEmpty)
            }
        }
        .formStyle(.columns)
        .padding()
        .onAppear {
            if !invalidAuthentication {
                self.tryReauthenticate()
            }
        }
    }
    
    func authenticate(storeCredentials: Bool = true) {
        let server = UmzugAPI.APIServer(scheme: .https, host: hostname, port: port)
        let auth = UmzugAPI.Authentication(username: username, password: password)
        self.api = .init(client: .shared, server: server, authentication: auth)
        
        if storeCredentials {
            try? keychainAdd(hostname, username: username, password: password)
        }
    }
    
    func tryReauthenticate() {
        if hostname.isEmpty { return }
        
        if let credentials = try? keychainFetch(hostname) {
            if let username = credentials.username { self.username = username }
            if let password = credentials.password { self.password = password }
            authenticate(storeCredentials: false)
        }
    }
}

#Preview {
    ContentView()
}

extension UInt16: @retroactive RawRepresentable {
    public var rawValue: String {
        self.description
    }
    
    public init?(rawValue: String) {
        self.init(rawValue)
    }
}

fileprivate extension View {
    func styleLoginViewTextfield() -> some View {
        self.textFieldStyle(.plain)
            .lineLimit(1)
            .font(.headline)
            .monospaced()
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(.gray)
            }
    }
    
    func styleLoginViewSectionHeader() -> some View {
        self.font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, 5)
            .frame(maxWidth: .infinity, alignment: .leadingFirstTextBaseline)
    }
}
