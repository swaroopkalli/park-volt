package com.parkvolt.gateway.filter;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.regex.Pattern;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

/** Demo-grade guard: admin-only routes require X-User-Role: ADMIN. */
@Component
public class AdminRoleFilter implements GlobalFilter, Ordered {
    private static final Pattern SLOTS = Pattern.compile("^/api/parking/slots/?$");
    private static final Pattern SLOT = Pattern.compile("^/api/parking/slots/\\d+/?$");
    private static final Pattern SLOT_STATUS = Pattern.compile("^/api/parking/slots/\\d+/status/?$");
    private static final Pattern STATION_STATUS = Pattern.compile("^/api/charging/stations/\\d+/status/?$");
    private static final Pattern BOOKINGS = Pattern.compile("^/api/bookings/?$");

    @Override
    public Mono<Void> filter(ServerWebExchange ex, GatewayFilterChain chain) {
        HttpMethod m = ex.getRequest().getMethod();
        String path = ex.getRequest().getURI().getPath();
        if (isAdminOnly(m, path) && !"ADMIN".equalsIgnoreCase(ex.getRequest().getHeaders().getFirst("X-User-Role"))) {
            var res = ex.getResponse();
            res.setStatusCode(HttpStatus.FORBIDDEN);
            res.getHeaders().setContentType(MediaType.APPLICATION_JSON);
            String body = "{\"timestamp\":\"" + Instant.now() + "\",\"status\":403,\"error\":\"FORBIDDEN\",\"message\":\"Admin role required\"}";
            return res.writeWith(Mono.just(res.bufferFactory().wrap(body.getBytes(StandardCharsets.UTF_8))));
        }
        return chain.filter(ex);
    }

    private boolean isAdminOnly(HttpMethod m, String p) {
        if (HttpMethod.POST.equals(m) && SLOTS.matcher(p).matches()) return true;
        if (HttpMethod.DELETE.equals(m) && SLOT.matcher(p).matches()) return true;
        if (HttpMethod.PATCH.equals(m) && (SLOT_STATUS.matcher(p).matches() || STATION_STATUS.matcher(p).matches())) return true;
        return HttpMethod.GET.equals(m) && BOOKINGS.matcher(p).matches();
    }

    @Override
    public int getOrder() { return -1; }
}
