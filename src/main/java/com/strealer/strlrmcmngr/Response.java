package com.strealer.strlrmcmngr;

import java.util.ArrayList;
import java.util.List;

public class Response {
    private int deviceId;
    private int operational;
    private List<Integer> errorCodeSet;

    public Response(int deviceId, int operational, List<Integer> errorCodeSet) {
        this.deviceId = deviceId;
        this.operational = operational;
        this.errorCodeSet = new ArrayList<>(errorCodeSet);
    }

    public int getDeviceId() {
        return deviceId;
    }

    public void setDeviceId(int deviceId) {
        this.deviceId = deviceId;
    }

    public int getOperational() {
        return operational;
    }

    public void setOperational(int operational) {
        this.operational = operational;
    }

    public List<Integer> getErrorCodeSet() {
        return errorCodeSet;
    }

    public void setErrorCodeSet(List<Integer> errorCodeSet) {
        this.errorCodeSet = errorCodeSet;
    }
}
