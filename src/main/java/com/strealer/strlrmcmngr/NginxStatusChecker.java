package com.strealer.strlrmcmngr;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.concurrent.TimeUnit;
import java.util.logging.Level;
import java.util.logging.Logger;

public class NginxStatusChecker {
    private static final Logger logger = Logger.getLogger(NginxStatusChecker.class.getName());
    private static final String COMMAND = "systemctl";
    private static final String ACTION = "status";
    private static final String SERVICE = "nginx";
    private static final long TIMEOUT_SECONDS = 10; // Define a reasonable timeout

    public static boolean isNginxRunning() {
        ProcessBuilder processBuilder = new ProcessBuilder(COMMAND, ACTION, SERVICE);
        processBuilder.redirectErrorStream(true); // Redirects error stream to the output stream

        Process process = null;
        try {
            process = processBuilder.start();
            boolean status = processStatus(process);
            // Wait for the process to terminate, with timeout
            boolean finished = process.waitFor(TIMEOUT_SECONDS, TimeUnit.SECONDS);

            if (!finished) {
                logger.log(Level.WARNING, "Timeout reached while waiting for the systemctl process to finish");
                return false; // Consider the service not running if timeout is reached
            }

            int exitValue = process.exitValue();
            if (exitValue != 0) {
                logger.log(Level.SEVERE, "Systemctl command exited with error code: {0}", exitValue);
                return false;
            }
            return status;
        } catch (IOException e) {
            logger.log(Level.SEVERE, "Error executing systemctl command", e);
            return false;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt(); // Reset the interrupt flag
            logger.log(Level.SEVERE, "Interrupted while waiting for the systemctl process to finish", e);
            return false;
        } finally {
            if (process != null) {
                process.destroy();
            }
        }
    }

    private static boolean processStatus(Process process) throws IOException {
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
        }
    }
}
