//
//  InstallXcode.swift
//  xcodeinstall
//
//  Created by Stormacq, Sebastien on 29/08/2022.
//

import CLIlib
import Foundation

// MARK: XCODE
// XCode installation functions
extension ShellInstaller {

    func installXcode(at src: URL) throws {

        // unXIP, mv, 4 PKG to install
        let totalSteps = 2 + PKGTOINSTALL.count
        var currentStep: Int = 0

        var resultOptional: CLIlib.ShellOutput?

        // first uncompress file
        log.debug("Decompressing files")
        // run synchronously as there is no output for this operation
        currentStep += 1
        env.progressBar.update(
            step: currentStep,
            total: totalSteps,
            text: "Expanding Xcode xip (this might take a while)"
        )
        resultOptional = try self.uncompressXIP(atURL: src)
        if resultOptional == nil || resultOptional!.code != 0 {
            log.error("Can not unXip file : \(resultOptional!)")
            throw InstallerError.xCodeXIPInstallationError
        }

        // second move file to /Applications
        log.debug("Moving app to destination")
        currentStep += 1
        env.progressBar.update(
            step: currentStep,
            total: totalSteps,
            text: "Moving Xcode to /Applications"
        )
        // find .app file
        let appFile = try env.fileHandler.downloadedFiles().filter({ fileName in
            return fileName.hasSuffix(".app")
        })
        if appFile.count != 1 {
            log.error(
                "Zero or several app file to install in \(appFile), not sure which one is the correct one"
            )
            throw InstallerError.xCodeMoveInstallationError
        }

        let installedFile =
            try self.moveApp(at: FileHandler.downloadDirectory.appendingPathComponent(appFile[0]))

        // /Applications/Xcode.app/Contents/Resources/Packages/

        // third install packages provided with Xcode app
        for pkg in PKGTOINSTALL {
            log.debug("Installing package \(pkg)")
            currentStep += 1
            env.progressBar.update(
                step: currentStep,
                total: totalSteps,
                text: "Installing additional packages... \(pkg)"
            )
            resultOptional = try self.installPkg(
                atURL: URL(fileURLWithPath: "\(installedFile)/Contents/resources/Packages/\(pkg)")
            )
            if resultOptional == nil || resultOptional!.code != 0 {
                log.error("Can not install pkg at : \(pkg)\n\(resultOptional!)")
                throw InstallerError.xCodePKGInstallationError
            }
        }

    }

    // expand a XIP file.  There is no way to create XIP file.
    // This code can not be tested without a valid, signed,  Xcode archive
    // https://en.wikipedia.org/wiki/.XIP
    func uncompressXIP(atURL file: URL) throws -> ShellOutput {

        let filePath = file.path

        // not necessary, file existence has been checked before
        guard env.fileHandler.fileExists(file: file, fileSize: 0) else {
            log.error("File to unXip does not exist : \(filePath)")
            throw InstallerError.fileDoesNotExistOrIncorrect
        }

        // synchronously uncompress in the download directory
        let cmd =
            "pushd \"\(FileHandler.downloadDirectory.path)\" && "
            + "\(XIPCOMMAND) --expand \"\(filePath)\" && " + "popd"
        let result = try env.shell.run(cmd)

        return result
    }

    func moveApp(at src: URL) throws -> String {

        // extract file name
        let fileName = src.lastPathComponent

        // create source and destination URL
        let appURL = URL(fileURLWithPath: "/Applications/\(fileName)")

        log.debug("Going to move \n \(src) to \n \(appURL)")
        // move synchronously
        try env.fileHandler.move(from: src, to: appURL)

        return appURL.path
    }
}
