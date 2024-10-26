package com.karamsawalha.azureupload;

import android.util.Log;
import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.concurrent.Executors;

public class AzureBackgroundUpload extends CordovaPlugin {

    private static final String TAG = "AzureUpload";

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (action.equals("uploadFiles")) {
            JSONArray files = args.getJSONArray(0);
            JSONObject azureDetails = args.getJSONObject(1);
            uploadFiles(files, azureDetails, callbackContext);
            return true;
        }
        return false;
    }

    private void uploadFiles(JSONArray files, JSONObject azureDetails, CallbackContext callbackContext) {
        Executors.newSingleThreadExecutor().execute(() -> {
            try {
                for (int i = 0; i < files.length(); i++) {
                    String filePath = files.getString(i);
                    uploadFile(filePath, azureDetails);
                }
                callbackContext.success("Files uploaded successfully.");
            } catch (Exception e) {
                Log.e(TAG, "Upload failed", e);
                callbackContext.error("Upload failed: " + e.getMessage());
            }
        });
    }

    private void uploadFile(String filePath, JSONObject azureDetails) throws Exception {
        // Get Azure details
        String storageUrl = azureDetails.getString("storageUrl");
        String sasToken = azureDetails.getString("sasToken");

        File file = new File(filePath);
        HttpURLConnection conn = (HttpURLConnection) new URL(storageUrl + file.getName() + "?" + sasToken).openConnection();
        conn.setDoOutput(true);
        conn.setRequestMethod("PUT");
        conn.setRequestProperty("x-ms-blob-type", "BlockBlob");
        conn.setRequestProperty("Content-Length", String.valueOf(file.length()));

        // Read file and upload
        InputStream inputStream = new FileInputStream(file);
        OutputStream outputStream = conn.getOutputStream();

        byte[] buffer = new byte[4096];
        int bytesRead;
        while ((bytesRead = inputStream.read(buffer)) != -1) {
            outputStream.write(buffer, 0, bytesRead);
        }
        outputStream.close();
        inputStream.close();

        if (conn.getResponseCode() != HttpURLConnection.HTTP_OK) {
            throw new Exception("Upload failed: " + conn.getResponseMessage());
        }
    }
}
