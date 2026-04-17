package com.example.order.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@RestController
@RequestMapping("/order")
public class OrderController {

    private static final Logger log = LoggerFactory.getLogger(OrderController.class);

    @Autowired
    private RestTemplate restTemplate;

    // 假设库存服务地址，生产环境建议使用服务发现名称如 http://trace-inventory
    private static final String INVENTORY_SERVICE_URL = "http://localhost:8082";

    @GetMapping("/test")
    public String test() {
        return "GET Test OK";
    }

    // 新增: 健康检查接口
    // 访问方式: GET http://localhost:8081/order/health (直连) 或 GET http://localhost:8080/order/health (通过网关)
    @GetMapping("/health")
    public String health() {
        log.info("Order service health check");
        return "Order Service is UP";
    }

    @PostMapping("/create")
    public String createOrder() {
        log.info("Order create endpoint hit");
        
        // 示例：调用库存服务检查库存
        try {
            String url = INVENTORY_SERVICE_URL + "/inventory/check?itemId=1";
            // 修改: 记录即将调用的 URL，方便排查是否调用了正确的地址
            log.info("Calling Inventory Service at URL: {}", url);
            
            String inventoryResult = restTemplate.getForObject(url, String.class);
            
            // 修改: 记录收到的响应内容
            log.info("Received Inventory Result: {}", inventoryResult);
            
            return "Order Created Successfully. Inventory Status: " + inventoryResult;
        } catch (Exception e) {
            log.error("Failed to check inventory. Exception: {}", e.getMessage(), e);
            return "Order Created but Inventory Check Failed: " + e.getMessage();
        }
    }
}