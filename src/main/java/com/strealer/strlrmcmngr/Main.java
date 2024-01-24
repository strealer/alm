package com.strealer.strlrmcmngr;

import java.io.File;
import java.io.IOException;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.*;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

public class Main {
    // Define configuration file path
    private static String CONFIG_FILE_PATH = "/etc/default/strealer.cnf";
    private static String CONFIG_FILE_DEFAULT_PATH = "\\target\\strlrmcmngr.cnf";
    // Define error container
    private static List<Integer> errorCodeSet = new ArrayList<>();
    // Declare Configuration object as global
    private static Configuration config;
    // Define timers
    private static Timer varnishCheckTimer;
    private static Timer heartbeatTimer;
    // Define heartbeat task
    //private static HeartbeatTask heartbeatTask;
    // Define configuration variables
    private static int nginxCheckInterval = 0;
    private static int heartbeatInterval = 0;

    private static ScheduledExecutorService executorService;
    private static Runnable nginxCheckTask;
    private static Runnable heartbeatTask;

    public static void main(String[] args) throws IOException {
//System.out.println(System.getProperty("user.dir"));
//System.exit(0);
//System.out.println(main.class.getProtectionDomain().getCodeSource().getLocation().getPath());
        final NginxService nginxService = new NginxService();
        int iterationCount = 0;
        try {
            if (!(new File(CONFIG_FILE_PATH)).exists()) {
                // Create the file and copy default contents, update CONFIG_FILE_PATH accordingly
//                CONFIG_FILE_PATH = createConfigFile(CONFIG_FILE_PATH, CONFIG_FILE_DEFAULT_PATH);
                CONFIG_FILE_PATH = System.getProperty("user.dir")+CONFIG_FILE_DEFAULT_PATH;
            }
            config = loadConfiguration(CONFIG_FILE_PATH);
            nginxCheckInterval = config.getNginxCheckInterval();
            heartbeatInterval = config.getHeartbeatInterval();

            executorService = Executors.newScheduledThreadPool(2);
            startTimers(nginxService);

            while (true) {
                try {
                    Thread.sleep(heartbeatInterval * 1000);
                    iterationCount = ((HeartbeatTask) heartbeatTask).getIterationCount();
                    System.out.println("HeartbeatTask iteration count: " + iterationCount);
                    if (iterationCount > 5) {
                        MemoryMonitor.print();
                        System.out.println("Restart timers!!!");
                        restartTimers(nginxService);
                        System.out.println("Timers reloaded!!!");
                        MemoryMonitor.print();
                    }
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    
    private static String createConfigFile(String targetPath, String defaultPath) throws IOException {
        try {
            Path configFile = Paths.get(targetPath);
            // Create parent directories if they don't exist
            Files.createDirectories(configFile.getParent());
            // Copy default contents to the new file
            Files.copy(Main.class.getResourceAsStream(defaultPath), configFile, StandardCopyOption.REPLACE_EXISTING);
            return configFile.toString(); // Return the correct file path
        } catch (IOException e) {
            e.printStackTrace(); // Handle the exception (e.g., logging)
            // If file creation/filling fails, fill config with fallback path
            return System.getProperty("user.dir") + defaultPath; // Return the fallback path
        }
    }

    private static Configuration loadConfiguration(String filePath) throws IOException {
        Properties properties = new Properties();
        try {
            Path path = Paths.get(filePath);
            properties.load(Files.newBufferedReader(path));

            Configuration config = new Configuration();
            config.setLocalHost(properties.getProperty("local_host"));
            config.setLocalPort(properties.getProperty("local_port"));
            config.setBackendHost(properties.getProperty("backend_host"));
            config.setBackendPort(properties.getProperty("backend_port"));
            config.setDeviceId(Integer.parseInt(properties.getProperty("device_id")));
            config.setRemoteApiUrl(properties.getProperty("remote_api_url"));
            config.setRemoteApiKey(properties.getProperty("remote_api_key"));
            config.setTestFilePath(properties.getProperty("test_file_path"));
            config.setHeartbeatInterval(Integer.parseInt(properties.getProperty("heartbeat_interval")));
            config.setNginxCheckInterval(Integer.parseInt(properties.getProperty("nginx_check_interval")));
            config.setNginxRestartTryMaxCount(Integer.parseInt(properties.getProperty("nginx_restart_try_max_count")));

            return config;
        } catch (IOException e) {
            e.printStackTrace();
            return null;
        }
    }

    private static void startTimers(NginxService nginxService) {
        nginxCheckTask = new NginxCheckTask(config, nginxService);
        executorService.scheduleAtFixedRate(nginxCheckTask, 0, nginxCheckInterval * 1000L, TimeUnit.NANOSECONDS);

        heartbeatTask = new HeartbeatTask(config, errorCodeSet);
        executorService.scheduleAtFixedRate(heartbeatTask, 0, heartbeatInterval * 1000L, TimeUnit.NANOSECONDS);
    }

    private static void restartTimers(NginxService nginxService) {
        cancelTimers();
        startTimers(nginxService);
    }

    private static void cancelTimers() {
        nginxCheckTask = null;
        heartbeatTask = null;
    }

    private static class NginxCheckTask implements Runnable {
        private final Configuration config;
        private final NginxService nginxService;

        public NginxCheckTask(Configuration config, NginxService nginxService) {
            this.config = config;
            this.nginxService = nginxService;
        }

        private int restartTryCount = 0;

        @Override
        public void run() {
            int nginxRestartTryMaxCount = config.getNginxRestartTryMaxCount();
            try {
                while (!NginxStatusChecker.isNginxRunning() && restartTryCount < nginxRestartTryMaxCount) {
                    try {
                        nginxService.restartNginx();
                        if (!NginxStatusChecker.isNginxRunning()) {
                            restartTryCount++;
                        } else {
                            removeErrorCode(2);
                            restartTryCount = 0;
                        }
                    } catch (IOException | InterruptedException e) {
                        restartTryCount++;
                        e.printStackTrace();
                    }
                    if (restartTryCount >= nginxRestartTryMaxCount) {
                        storeErrorCode(2);
                        restartTryCount = 0;
                        break;
                    }
                }
            } catch (IOException e) {
                restartTryCount++;
                e.printStackTrace();
            }
            if (restartTryCount >= nginxRestartTryMaxCount) {
                storeErrorCode(2);
                restartTryCount = 0;
            }
        }
    }

    private static class HeartbeatTask implements Runnable {
        private final Configuration config;
        private final List<Integer> errorCodeSet;
        private int iterationCount;

        public HeartbeatTask(Configuration config, List<Integer> errorCodeSet) {
            this.config = config;
            this.errorCodeSet = errorCodeSet;
            this.iterationCount = 0;
        }

        @Override
        public void run() {
            String localHostPort = config.getLocalHostPort();
            String backendHostPort = config.getBackendHostPort();
            String testFilePath = config.getTestFilePath();
            String remoteApiUrl = config.getRemoteApiUrl();
            String remoteApiKey = config.getRemoteApiKey();
            int deviceId = config.getDeviceId();
            boolean localHostSuccess = testFileConnection(localHostPort, testFilePath);
            if (!localHostSuccess) {
                storeErrorCode(3);
            } else {
                removeErrorCode(3);
            }

            boolean backendHostSuccess = testFileConnection(backendHostPort, testFilePath);
            if (!backendHostSuccess) {
                storeErrorCode(4);
            } else {
                removeErrorCode(4);
            }

            Response response = new Response(deviceId, isOperational(), getErrorCodeSet());
            clearErrorCodeSet();
            String responseJson = convertToJson(response);

            //Send response to remote API URL
            /*postResponse(remoteApiUrl, remoteApiKey, responseJson);*/

            iterationCount++;
            MemoryMonitor.print();
        }

        public int getIterationCount() {
            return iterationCount;
        }
    }

    // Test the file
    /*private static boolean testFileConnection(String hostPort, String testFilePath) {*/
    public static boolean testFileConnection(String hostPort, String testFilePath) {
        try {
            URL url = new URL(hostPort + "/" + testFilePath);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("GET");

            int responseCode = connection.getResponseCode();
            return responseCode == HttpURLConnection.HTTP_OK;
        } catch (IOException e) {
            return false;
        }
    }

    // Convert reponse to JSON
    private static String convertToJson(Response response) {
        StringBuilder jsonBuilder = new StringBuilder();
        jsonBuilder.append("{");
        jsonBuilder.append("\"device_id\": ").append(response.getDeviceId()).append(",");
        jsonBuilder.append("\"operational\": ").append(response.getOperational()).append(",");
        jsonBuilder.append("\"error_code_set\": [");

        List<Integer> errorCodeSet = response.getErrorCodeSet();
        for (int i = 0; i < errorCodeSet.size(); i++) {
            jsonBuilder.append(errorCodeSet.get(i));
            if (i < errorCodeSet.size() - 1) {
                jsonBuilder.append(",");
            }
        }

        jsonBuilder.append("]}");
        return jsonBuilder.toString();
    }

    // Post response to remote API
    private static void postResponse(String remoteApiUrl, String remoteApiKey, String responseJson) {
        HttpURLConnection connection = null;
        OutputStream outputStream = null;

        try {
            URL url = new URL(remoteApiUrl);
            connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("POST");
            connection.setRequestProperty("Content-Type", "application/json");
            connection.setRequestProperty("x-api-key", remoteApiKey);
            connection.setDoOutput(true);

            // Write the response JSON to the connection output stream
            outputStream = connection.getOutputStream();
            outputStream.write(responseJson.getBytes());
            outputStream.flush();

            int responseCode = connection.getResponseCode();

            // Check the response code and handle accordingly
            if (responseCode != HttpURLConnection.HTTP_OK) {
                // Response failed
                System.out.println("Failed to post the response. Response code: " + responseCode);
            }
        } catch (IOException e) {
            // Handle the exception appropriately
            e.printStackTrace();
        } finally {
            if (outputStream != null) {
                try {
                    outputStream.close();
                } catch (IOException e) {
                    // Handle the exception appropriately
                    e.printStackTrace();
                }
            }
        }
    }

    // Store error code
    private static void storeErrorCode(int errorCode) {
        if (!errorCodeSet.contains(errorCode)) {
            errorCodeSet.add(errorCode);
        }
    }

    // Remove error code
    private static void removeErrorCode(int errorCode) {
//        errorCodeSet.remove(errorCode);
        Iterator<Integer> iterator = errorCodeSet.iterator();
        while (iterator.hasNext()) {
            Integer element = iterator.next();
            if (element.equals(errorCode)) {
                iterator.remove();
            }
        }
    }

    // Is cache operational
    private static int isOperational() {
        return errorCodeSet.isEmpty() ? 1 : 0;
    }

    // Return ErrorCodeSet
    private static List<Integer> getErrorCodeSet() {
        return errorCodeSet;
    }

    // Clear ErrorCodeSet
    private static void clearErrorCodeSet() {
        errorCodeSet.clear();
    }

    // Debug error code set
    private static void debugErrorCodeSet() {
        System.out.println("ErrorCodeSet:");
        List<Integer> errorSet = getErrorCodeSet();
        /*Iterator<Integer> iterator = errorCodeSet.iterator();*/
        Iterator<Integer> iterator = errorSet.iterator();
        while (iterator.hasNext()) {
            Integer element = iterator.next();
            System.out.println("id: " + element);
        }
    }
}