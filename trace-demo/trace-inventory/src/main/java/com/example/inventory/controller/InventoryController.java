package com.example.inventory.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

// 修改: 指定唯一的 Bean 名称，避免与其他包下同名的 InventoryController 冲突
@RestController("inventoryControllerEndpoint")
@RequestMapping("/inventory")
public class InventoryController {

    private static final Logger log = LoggerFactory.getLogger(InventoryController.class);

    @GetMapping("/check")
    public String checkInventory(@RequestParam(required = false, defaultValue = "1") String itemId) {
        // 修改: 增加 System.out.println 以确保在日志配置不正确时也能在控制台看到输出，方便调试
        System.out.println("[INVENTORY-SERVICE] Received request for itemId: " + itemId);
        log.info("=== Inventory check endpoint hit for itemId: {} ===", itemId);
        
        // 模拟库存充足
        String response = "Inventory OK for item: " + itemId;
        log.info("Returning response: {}", response);
        return response;
    }

    // 新增: 健康检查接口
    // 访问方式: GET http://localhost:8082/inventory/health (直连) 或 GET http://localhost:8080/inventory/health (通过网关)
    @GetMapping("/health")
    public String health() {
        log.info("Inventory service health check");
        return "Inventory Service is UP";
    }
}