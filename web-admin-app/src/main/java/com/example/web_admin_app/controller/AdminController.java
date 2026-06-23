package com.example.web_admin_app.controller;

import com.example.web_admin_app.dto.CategoryDto;
import com.example.web_admin_app.dto.ProductDto;
import com.example.web_admin_app.service.CentralServiceRestClient;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.math.BigDecimal;
import java.util.List;

@Controller
@RequestMapping("/admin")
public class AdminController {

    private final CentralServiceRestClient restClient;

    public AdminController(CentralServiceRestClient restClient) {
        this.restClient = restClient;
    }

    @GetMapping
    public String showAdminPanel(Model model) {
        List<ProductDto> products = restClient.getAllProductsFromDb();
        List<CategoryDto> categories = restClient.getAllCategories();

        model.addAttribute("products", products);
        model.addAttribute("categories", categories);
        model.addAttribute("newProduct", new ProductDto());
        
        return "admin";
    }

    @PostMapping("/save")
    public String saveProduct(@RequestParam(required = false) Long id,
                              @RequestParam String name,
                              @RequestParam String description,
                              @RequestParam BigDecimal price,
                              @RequestParam Long categoryId,
                              RedirectAttributes redirectAttributes) {
        try {
            ProductDto product = new ProductDto();
            product.setId(id);
            product.setName(name);
            product.setDescription(description);
            product.setPrice(price);
            
            CategoryDto category = new CategoryDto();
            category.setId(categoryId);
            product.setCategory(category);

            restClient.saveProduct(product);
            redirectAttributes.addFlashAttribute("successMessage", "Product saved successfully! Database and cache updated.");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", "Error saving product: " + e.getMessage());
        }
        return "redirect:/admin";
    }

    @GetMapping("/delete/{id}")
    public String deleteProduct(@PathVariable Long id, RedirectAttributes redirectAttributes) {
        try {
            restClient.deleteProduct(id);
            redirectAttributes.addFlashAttribute("successMessage", "Product deleted successfully! Database and cache updated.");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", "Error deleting product: " + e.getMessage());
        }
        return "redirect:/admin";
    }

    @PostMapping("/cache-refresh")
    public String triggerCacheRefresh(RedirectAttributes redirectAttributes) {
        String result = restClient.triggerCacheRefresh();
        redirectAttributes.addFlashAttribute("successMessage", "Cache refresh status: " + result);
        return "redirect:/admin";
    }
}
