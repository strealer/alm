package com.strealer.strlrmcmngr;

public class Configuration {
    private String localHost;
    private String localPort;
    private String backendHost;
    private String backendPort;
    private int deviceId;
    private String remoteApiUrl;
    private String remoteApiKey;
    private String testFilePath;
    private int heartbeatInterval;
    private int nginxCheckInterval;
    private int nginxRestartTryMaxCount;

    public Configuration() {
    }

    public String getLocalHost() {
        return localHost;
    }

    public void setLocalHost(String localHost) {
        this.localHost = localHost;
    }

    public String getLocalPort() {
        return localPort;
    }

    public void setLocalPort(String localPort) {
        this.localPort = localPort;
    }

    public String getLocalHostPort() {
        String localHostPort = localHost;
        if (!localPort.isEmpty()) {
            localHostPort += ":" + localPort;
        }
        return localHostPort;
    }

    public String getBackendHost() {
        return backendHost;
    }

    public void setBackendHost(String backendHost) {
        this.backendHost = backendHost;
    }

    public String getBackendPort() {
        return backendPort;
    }

    public void setBackendPort(String backendPort) {
        this.backendPort = backendPort;
    }

    public String getBackendHostPort() {
        String backendHostPort = backendHost;
        if (!backendPort.isEmpty()) {
            backendHostPort += ":" + backendPort;
        }
        return backendHostPort;
    }

    public int getDeviceId() {
        return deviceId;
    }

    public void setDeviceId(int deviceId) {
        this.deviceId = deviceId;
    }

    public String getRemoteApiUrl() {
        return remoteApiUrl;
    }

    public void setRemoteApiUrl(String remoteApiUrl) {
        this.remoteApiUrl = remoteApiUrl;
    }

    public String getRemoteApiKey() {
        return remoteApiKey;
    }

    public void setRemoteApiKey(String remoteApiKey) {
        this.remoteApiKey = remoteApiKey;
    }

    public String getTestFilePath() {
        return testFilePath;
    }

    public void setTestFilePath(String testFilePath) {
        this.testFilePath = testFilePath;
    }

    public int getHeartbeatInterval() {
        return heartbeatInterval;
    }

    public void setHeartbeatInterval(int heartbeatInterval) {
        this.heartbeatInterval = heartbeatInterval;
    }

    public int getNginxCheckInterval() {
        return nginxCheckInterval;
    }

    public void setNginxCheckInterval(int nginxCheckInterval) {
        this.nginxCheckInterval = nginxCheckInterval;
    }

    public int getNginxRestartTryMaxCount() {
        return nginxRestartTryMaxCount;
    }

    public void setNginxRestartTryMaxCount(int nginxRestartTryMaxCount) {
        this.nginxRestartTryMaxCount = nginxRestartTryMaxCount;
    }
}
