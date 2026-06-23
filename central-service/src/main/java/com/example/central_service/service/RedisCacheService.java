package com.example.central_service.service;

import com.example.central_service.model.Category;
import com.example.central_service.model.Product;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class RedisCacheService {

    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;

    private static final String PRODUCTS_CACHE_KEY = "products:all";
    private static final String CATEGORIES_CACHE_KEY = "categories:all";

    public RedisCacheService(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
        this.objectMapper = new ObjectMapper();
        this.objectMapper.registerModule(new JavaTimeModule()); // Support Java 8 Date/Time API
    }

    public void cacheProducts(List<Product> products) {
        try {
            String json = objectMapper.writeValueAsString(products);
            redisTemplate.opsForValue().set(PRODUCTS_CACHE_KEY, json);
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Failed to serialize products for caching", e);
        }
    }

    public void cacheCategories(List<Category> categories) {
        try {
            String json = objectMapper.writeValueAsString(categories);
            redisTemplate.opsForValue().set(CATEGORIES_CACHE_KEY, json);
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Failed to serialize categories for caching", e);
        }
    }

    public void clearCache() {
        redisTemplate.delete(PRODUCTS_CACHE_KEY);
        redisTemplate.delete(CATEGORIES_CACHE_KEY);
    }
}
