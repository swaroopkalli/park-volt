package com.parkvolt.gateway.error;

import java.net.ConnectException;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.concurrent.TimeoutException;
import org.springframework.cloud.gateway.route.Route;
import org.springframework.cloud.gateway.support.ServerWebExchangeUtils;
import org.springframework.core.annotation.Order;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.boot.web.reactive.error.ErrorWebExceptionHandler;
import reactor.core.publisher.Mono;

/** Turns unreachable-downstream failures into the contract's 503 JSON; other errors keep a JSON shape too. */
@Component
@Order(-2)
public class DownstreamErrorHandler implements ErrorWebExceptionHandler {
    @Override
    public Mono<Void> handle(ServerWebExchange ex, Throwable t) {
        var res = ex.getResponse();
        if (res.isCommitted()) return Mono.error(t);
        Route route = ex.getAttribute(ServerWebExchangeUtils.GATEWAY_ROUTE_ATTR);
        HttpStatus status;
        String code, msg, extra = "";
        if (isDownstreamDown(t)) {
            status = HttpStatus.SERVICE_UNAVAILABLE;
            code = "SERVICE_UNAVAILABLE";
            String svc = route != null ? route.getId() : "unknown";
            msg = svc + " is unavailable";
            extra = ",\"service\":\"" + svc + "\"";
        } else if (t instanceof ResponseStatusException rse) {
            status = HttpStatus.valueOf(rse.getStatusCode().value());
            code = status == HttpStatus.NOT_FOUND ? "NOT_FOUND" : status.name();
            msg = status.getReasonPhrase();
        } else {
            status = HttpStatus.INTERNAL_SERVER_ERROR;
            code = "GATEWAY_ERROR";
            msg = "Unexpected gateway error";
        }
        res.setStatusCode(status);
        res.getHeaders().setContentType(MediaType.APPLICATION_JSON);
        String body = "{\"timestamp\":\"" + Instant.now() + "\",\"status\":" + status.value() + ",\"error\":\"" + code
                + "\",\"message\":\"" + msg + "\"" + extra + "}";
        return res.writeWith(Mono.just(res.bufferFactory().wrap(body.getBytes(StandardCharsets.UTF_8))));
    }

    private boolean isDownstreamDown(Throwable t) {
        for (Throwable c = t; c != null; c = c.getCause()) {
            if (c instanceof ConnectException || c instanceof TimeoutException) return true;
            if (c instanceof ResponseStatusException r && (r.getStatusCode().value() == 503 || r.getStatusCode().value() == 504)) return true;
            String n = c.getClass().getName();
            if (n.contains("ConnectTimeoutException") || n.contains("AnnotatedConnectException")) return true;
        }
        return false;
    }
}
