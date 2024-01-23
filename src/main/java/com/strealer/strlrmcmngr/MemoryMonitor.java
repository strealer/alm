package com.strealer.strlrmcmngr;

import java.lang.management.ManagementFactory;
import java.lang.management.MemoryMXBean;
import java.lang.management.MemoryUsage;

public class MemoryMonitor {
    /*public static void main(String[] args) {*/
    public static void print() {
        // Get the MemoryMXBean
        MemoryMXBean memoryBean = ManagementFactory.getMemoryMXBean();

        // Get the heap memory usage
        MemoryUsage heapMemoryUsage = memoryBean.getHeapMemoryUsage();
        System.out.println("----------------------");
        System.out.println("Heap Memory Usage:");
        System.out.println("  Initial: " + bytesToMegabytes(heapMemoryUsage.getInit()) + " MB");
        System.out.println("  Used: " + bytesToMegabytes(heapMemoryUsage.getUsed()) + " MB");
        System.out.println("  Committed: " + bytesToMegabytes(heapMemoryUsage.getCommitted()) + " MB");
        System.out.println("  Max: " + bytesToMegabytes(heapMemoryUsage.getMax()) + " MB");

        // Get the non-heap memory usage
        /*MemoryUsage nonHeapMemoryUsage = memoryBean.getNonHeapMemoryUsage();
        System.out.println("");
        System.out.println("Non-Heap Memory Usage:");
        System.out.println("  Initial: " + nonHeapMemoryUsage.getInit() + " bytes");
        System.out.println("  Used: " + nonHeapMemoryUsage.getUsed() + " bytes");
        System.out.println("  Committed: " + nonHeapMemoryUsage.getCommitted() + " bytes");
        System.out.println("  Max: " + nonHeapMemoryUsage.getMax() + " bytes");*/
    }

    private static double bytesToMegabytes(long bytes) {
        return (double) bytes / (1024 * 1024);
    }
}
