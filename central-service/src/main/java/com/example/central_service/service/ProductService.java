package com.example.central_service.service;

import com.example.central_service.model.Category;
import com.example.central_service.model.Product;
import com.example.central_service.repository.CategoryRepository;
import com.example.central_service.repository.ProductRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class ProductService {

    private final ProductRepository productRepository;
    private final CategoryRepository categoryRepository;
    private final RedisCacheService redisCacheService;

    public ProductService(ProductRepository productRepository,
                          CategoryRepository categoryRepository,
                          RedisCacheService redisCacheService) {
        this.productRepository = productRepository;
        this.categoryRepository = categoryRepository;
        this.redisCacheService = redisCacheService;
    }

    public List<Product> getAllProducts() {
        return productRepository.findAll();
    }

    public List<Category> getAllCategories() {
        return categoryRepository.findAll();
    }

    public Optional<Product> getProductById(Long id) {
        return productRepository.findById(id);
    }

    public Product saveProduct(Product product) {
        // Resolve Category if it exists or save it
        if (product.getCategory() != null) {
            Category category = product.getCategory();
            if (category.getId() == null && category.getName() != null) {
                Category finalCategory = category;
                Category resolvedCategory = categoryRepository.findByName(category.getName())
                        .orElseGet(() -> categoryRepository.save(finalCategory));
                product.setCategory(resolvedCategory);
            } else if (category.getId() != null) {
                Category resolvedCategory = categoryRepository.findById(category.getId())
                        .orElseThrow(() -> new IllegalArgumentException("Category not found with ID: " + category.getId()));
                product.setCategory(resolvedCategory);
            }
        }
        
        Product savedProduct = productRepository.save(product);
        refreshCache();
        return savedProduct;
    }

    public void deleteProduct(Long id) {
        productRepository.deleteById(id);
        refreshCache();
    }

    public void refreshCache() {
        List<Product> products = productRepository.findAll();
        List<Category> categories = categoryRepository.findAll();
        redisCacheService.cacheProducts(products);
        redisCacheService.cacheCategories(categories);
    }
}
