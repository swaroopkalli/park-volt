package com.parkvolt.gateway.health;

import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

@RestController
public class HealthAggregator {
    private final Map<String, String> urls = new LinkedHashMap<>();
    private final WebClient client = WebClient.create();

    public HealthAggregator(@Value("${parkvolt.services.parking}") String parking,
                            @Value("${parkvolt.services.booking}") String booking,
                            @Value("${parkvolt.services.charging}") String charging) {
        urls.put("parking-service", parking);
        urls.put("booking-service", booking);
        urls.put("charging-service", charging);
    }

    @GetMapping("/api/health")
    public Mono<Map<String, Object>> health() {
        return Mono.zip(urls.entrySet().stream().map(e -> check(e.getKey(), e.getValue())).toList(), arr -> {
            Map<String, String> services = new LinkedHashMap<>();
            boolean allUp = true;
            for (Object o : arr) {
                @SuppressWarnings("unchecked") Map.Entry<String, String> en = (Map.Entry<String, String>) o;
                services.put(en.getKey(), en.getValue());
                allUp &= "UP".equals(en.getValue());
            }
            Map<String, Object> out = new LinkedHashMap<>();
            out.put("status", allUp ? "UP" : "DEGRADED");
            out.put("services", services);
            return out;
        });
    }

    private Mono<Map.Entry<String, String>> check(String name, String url) {
        return client.get().uri(url + "/health").retrieve().bodyToMono(Map.class)
                .timeout(Duration.ofSeconds(2))
                .map(b -> "UP".equals(b.get("status")) ? "UP" : "DOWN")
                .onErrorReturn("DOWN")
                .map(s -> Map.entry(name, s));
    }
}
