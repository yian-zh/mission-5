package com.example.web_admin_app.service;

import com.example.web_admin_app.dto.CategoryDto;
import com.example.web_admin_app.dto.ProductDto;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.Collections;
import java.util.List;

@Service
public class RedisCacheService {

    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;
    private final RestTemplate restTemplate;

    @Value("${central.service.url}")
    private String centralServiceUrl;

    private static final String PRODUCTS_CACHE_KEY = "products:all";
    private static final String CATEGORIES_CACHE_KEY = "categories:all";

    public RedisCacheService(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
        this.restTemplate = new RestTemplate();
        this.objectMapper = new ObjectMapper();
        this.objectMapper.registerModule(new JavaTimeModule());
    }

    public List<ProductDto> getCachedProducts() {
        String json = redisTemplate.opsForValue().get(PRODUCTS_CACHE_KEY);
        if (json == null || json.isEmpty()) {
            // Self-healing: trigger cache refresh via Central Service
            triggerCentralServiceRefresh();
            json = redisTemplate.opsForValue().get(PRODUCTS_CACHE_KEY);
        }
        if (json == null || json.isEmpty()) {
            return Collections.emptyList();
        }
        try {
            return objectMapper.readValue(json, new TypeReference<List<ProductDto>>() {});
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }

    public List<CategoryDto> getCachedCategories() {
        String json = redisTemplate.opsForValue().get(CATEGORIES_CACHE_KEY);
        if (json == null || json.isEmpty()) {
            triggerCentralServiceRefresh();
            json = redisTemplate.opsForValue().get(CATEGORIES_CACHE_KEY);
        }
        if (json == null || json.isEmpty()) {
            return Collections.emptyList();
        }
        try {
            return objectMapper.readValue(json, new TypeReference<List<CategoryDto>>() {});
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }

    private void triggerCentralServiceRefresh() {
        try {
            restTemplate.postForObject(centralServiceUrl + "/cache/refresh", null, String.class);
        } catch (Exception e) {
            System.err.println("Failed to trigger central service refresh: " + e.getMessage());
        }
    }
}
