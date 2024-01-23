package com.strealer.strlrmcmngr;

import java.io.IOException;

public class NginxService {
    private static final String SYSTEMCTL_COMMAND = "sudo systemctl";
    private static final String VAR_NGINX = "nginx";

    public static void startNginx() throws IOException, InterruptedException {
        executeSystemCommand("start");
    }

    public static void stopNginx() throws IOException, InterruptedException {
        executeSystemCommand("stop");
    }

    public static void restartNginx() throws IOException, InterruptedException {
        if (!NginxStatusChecker.isNginxRunning()) {
            startNginx();
        } else {
            executeSystemCommand("restart");
        }
    }

    private static void executeSystemCommand(String action) throws IOException, InterruptedException {
        ProcessBuilder processBuilder = new ProcessBuilder(SYSTEMCTL_COMMAND, action, VAR_NGINX);
        Process process = processBuilder.start();
        process.waitFor();
    }


}
