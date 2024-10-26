import Foundation
import Cordova

@objc(AzureBackgroundUpload)
class AzureBackgroundUpload: CDVPlugin {

    @objc(uploadFiles:)
    func uploadFiles(command: CDVInvokedUrlCommand) {
        guard let files = command.arguments[0] as? [String],
              let azureDetails = command.arguments[1] as? [String: String] else {
            let errorResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid arguments.")
            self.commandDelegate.send(errorResult, callbackId: command.callbackId)
            return
        }

        let storageUrl = azureDetails["storageUrl"] ?? ""
        let sasToken = azureDetails["sasToken"] ?? ""

        for filePath in files {
            uploadFile(filePath: filePath, storageUrl: storageUrl, sasToken: sasToken, command: command)
        }
    }

    private func uploadFile(filePath: String, storageUrl: String, sasToken: String, command: CDVInvokedUrlCommand) {
        guard let url = URL(string: "\(storageUrl)\(URL(fileURLWithPath: filePath).lastPathComponent)?\(sasToken)") else {
            let errorResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid URL.")
            self.commandDelegate.send(errorResult, callbackId: command.callbackId)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("BlockBlob", forHTTPHeaderField: "x-ms-blob-type")
        request.setValue(String(FileManager.default.attributesOfItem(atPath: filePath)[.size] as! NSNumber), forHTTPHeaderField: "Content-Length")

        let fileData = try? Data(contentsOf: URL(fileURLWithPath: filePath))
        request.httpBody = fileData

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                let errorResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error.localizedDescription)
                self.commandDelegate.send(errorResult, callbackId: command.callbackId)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
                let errorResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Upload failed.")
                self.commandDelegate.send(errorResult, callbackId: command.callbackId)
                return
            }

            let successResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "File uploaded successfully.")
            self.commandDelegate.send(successResult, callbackId: command.callbackId)
        }

        task.resume()
    }
}
