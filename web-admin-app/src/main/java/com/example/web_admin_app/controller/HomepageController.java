package com.example.web_admin_app.controller;

import com.example.web_admin_app.dto.CategoryDto;
import com.example.web_admin_app.dto.ProductDto;
import com.example.web_admin_app.service.RedisCacheService;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import java.util.List;

@Controller
public class HomepageController {

    private final RedisCacheService redisCacheService;

    public HomepageController(RedisCacheService redisCacheService) {
        this.redisCacheService = redisCacheService;
    }

    @GetMapping("/")
    public String showHomepage(Model model) {
        // Retrieve data STRICTLY from Redis cache, not PostgreSQL
        List<ProductDto> products = redisCacheService.getCachedProducts();
        List<CategoryDto> categories = redisCacheService.getCachedCategories();

        model.addAttribute("products", products);
        model.addAttribute("categories", categories);
        model.addAttribute("dataSource", "Redis Cache");
        
        return "index";
    }
}
