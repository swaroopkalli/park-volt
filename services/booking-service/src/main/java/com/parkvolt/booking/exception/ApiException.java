package com.parkvolt.booking.exception;

import java.util.Map;
import org.springframework.http.HttpStatus;

public class ApiException extends RuntimeException {
    private final HttpStatus status;
    private final String code;
    private final Map<String, Object> extra;

    public ApiException(HttpStatus status, String code, String message) { this(status, code, message, Map.of()); }

    public ApiException(HttpStatus status, String code, String message, Map<String, Object> extra) {
        super(message);
        this.status = status;
        this.code = code;
        this.extra = extra;
    }
    public HttpStatus getStatus() { return status; }
    public String getCode() { return code; }
    public Map<String, Object> getExtra() { return extra; }

    public static ApiException unavailable(String service) {
        return new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "SERVICE_UNAVAILABLE", service + " is unavailable", Map.of("service", service));
    }
}
