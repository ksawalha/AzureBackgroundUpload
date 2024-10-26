var AzureBackgroundUpload = {
    uploadFiles: function (files, azureDetails, successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "AzureBackgroundUpload", "uploadFiles", [files, azureDetails]);
    }
};

module.exports = AzureBackgroundUpload;
