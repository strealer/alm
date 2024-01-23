package com.strealer.strlrmcmngr;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

public class NginxStatusChecker {
    public static boolean isNginxRunning() throws IOException {
        ProcessBuilder processBuilder = new ProcessBuilder("sudo", "systemctl", "status", "nginx");
        Process process = null;
        try {
            process = processBuilder.start();
        } catch (IOException e) {
            e.printStackTrace();
            throw new IOException(e);
        } finally {
            assert process != null;
            process.destroy();
        }
        try {
            process.waitFor();
        } catch (InterruptedException e) {
            // Handle the InterruptedException appropriately
            e.printStackTrace();
        }
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
            String line;
            boolean loaded = false;
            boolean active = false;
            while ((line = reader.readLine()) != null) {
                if (line.contains("Loaded: loaded")) {
                    loaded = true;
                }
                if (line.contains("Active: active (running)")) {
                    active = true;
                }
            }
            return loaded && active;
        } catch (IOException e) {
            // Handle the exception appropriately
            e.printStackTrace();
        }
        return false;
    }
}
