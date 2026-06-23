package com.example.web_admin_app.service;

import com.example.web_admin_app.dto.CategoryDto;
import com.example.web_admin_app.dto.ProductDto;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

@Service
public class CentralServiceRestClient {

    private final RestTemplate restTemplate;

    @Value("${central.service.url}")
    private String centralServiceUrl;

    public CentralServiceRestClient() {
        this.restTemplate = new RestTemplate();
    }

    public List<CategoryDto> getAllCategories() {
        try {
            CategoryDto[] categories = restTemplate.getForObject(centralServiceUrl + "/categories", CategoryDto[].class);
            return categories != null ? Arrays.asList(categories) : Collections.emptyList();
        } catch (Exception e) {
            System.err.println("Error calling Central Service for categories: " + e.getMessage());
            return Collections.emptyList();
        }
    }

    public List<ProductDto> getAllProductsFromDb() {
        try {
            ProductDto[] products = restTemplate.getForObject(centralServiceUrl + "/products", ProductDto[].class);
            return products != null ? Arrays.asList(products) : Collections.emptyList();
        } catch (Exception e) {
            System.err.println("Error calling Central Service for products: " + e.getMessage());
            return Collections.emptyList();
        }
    }

    public ProductDto saveProduct(ProductDto productDto) {
        try {
            return restTemplate.postForObject(centralServiceUrl + "/products", productDto, ProductDto.class);
        } catch (Exception e) {
            throw new RuntimeException("Failed to save product in Central Database: " + e.getMessage(), e);
        }
    }

    public void deleteProduct(Long id) {
        try {
            restTemplate.delete(centralServiceUrl + "/products/" + id);
        } catch (Exception e) {
            throw new RuntimeException("Failed to delete product in Central Database: " + e.getMessage(), e);
        }
    }

    public String triggerCacheRefresh() {
        try {
            return restTemplate.postForObject(centralServiceUrl + "/cache/refresh", null, String.class);
        } catch (Exception e) {
            return "Failed to trigger cache refresh: " + e.getMessage();
        }
    }
}
