//
//  File.swift
//  xcodeinstall
//
//  Created by Stormacq, Sebastien on 22/08/2022.
//

import Foundation
import Logging

class XCodeInstallBuilder {

    private var verbosity: Logger.Level = .warning

    private var authenticatorNeeded: Bool = false
    private var downloaderNeeded: Bool = false
    private var installerNeeded: Bool = false

    func with(verbosityLevel: Logger.Level) -> XCodeInstallBuilder {
        self.verbosity = verbosityLevel
        return self
    }
    func withDownloader() -> XCodeInstallBuilder {
        self.downloaderNeeded = true
        return self
    }
    func withAuthenticator() -> XCodeInstallBuilder {
        self.authenticatorNeeded = true
        return self
    }
    func withInstaller() -> XCodeInstallBuilder {
        self.installerNeeded = true
        return self
    }
    func build() -> XCodeInstall {
        let log = Log(logLevel: self.verbosity)

        // TODO add choice between file and Secrets Manager
        let secretsManager = FileSecretsHandler(logger: log.defaultLogger)

        guard downloaderNeeded || authenticatorNeeded || installerNeeded else {
            fatalError("This command requires either an authenticator,a downloader, or an installer")
        }

        var result: XCodeInstall?

        if authenticatorNeeded {
            let auth = AppleAuthenticator(logger: log.defaultLogger, secrets: secretsManager)
            result = XCodeInstall(authenticator: auth, secretsManager: secretsManager, logger: log.defaultLogger)
        }

        if downloaderNeeded {
            let down = AppleDownloader(logger: log.defaultLogger, secrets: secretsManager)
            result = XCodeInstall(downloader: down, secretsManager: secretsManager, logger: log.defaultLogger)
        }

        if installerNeeded {
            let inst = ShellInstaller(logger: log.defaultLogger, shell: AsyncShell())
            result = XCodeInstall(installer: inst, secretsManager: secretsManager, logger: log.defaultLogger)
        }

        // at this stage the guard statement ensured result is initialized
        return result!
    }
}
