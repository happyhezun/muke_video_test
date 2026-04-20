package com.example.order.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.annotation.PostConstruct;

@RestController
@RequestMapping("/order")
public class OrderController {

    private static final Logger log = LoggerFactory.getLogger(OrderController.class);

    @Autowired
    private RestTemplate restTemplate;

    // 注入环境标识
    @Value("${app.environment:UNKNOWN}")
    private String environment;
    
    @Value("${app.environment-name:未知环境}")
    private String environmentName;

    // 假设库存服务地址，生产环境建议使用服务发现名称如 http://trace-inventory
    private static final String INVENTORY_SERVICE_URL = "http://localhost:8082";

    /**
     * 服务启动时打印醒目的环境标识
     */
    @PostConstruct
    public void init() {
        log.info("=================================================");
        log.info("===  订单服务启动 - 当前环境: [{}] {}  ===", environment, environmentName);
        log.info("=================================================");
    }

    @GetMapping("/test")
    public String test() {
        return "GET Test OK - Environment: " + environment;
    }

    // 新增: 健康检查接口
    // 访问方式: GET http://localhost:8081/order/health (直连) 或 GET http://localhost:8080/order/health (通过网关)
    @GetMapping("/health")
    public String health() {
        log.info("Order service health check - Environment: {}", environment);
        return "Order Service is UP | Environment: [" + environment + "] " + environmentName;
    }

    @PostMapping("/create")
    public String createOrder() {
        log.info("[{}] Order create endpoint hit", environment);
        
        // 示例：调用库存服务检查库存
        try {
            String url = INVENTORY_SERVICE_URL + "/inventory/check?itemId=1";
            // 修改: 记录即将调用的 URL，方便排查是否调用了正确的地址
            log.info("[{}] Calling Inventory Service at URL: {}", environment, url);
            
            String inventoryResult = restTemplate.getForObject(url, String.class);
            
            // 修改: 记录收到的响应内容
            log.info("[{}] Received Inventory Result: {}", environment, inventoryResult);
            
            return "Order Created Successfully. Inventory Status: " + inventoryResult + 
                   " | Environment: [" + environment + "] " + environmentName;
        } catch (Exception e) {
            log.error("[{}] Failed to check inventory. Exception: {}", environment, e.getMessage(), e);
            return "Order Created but Inventory Check Failed: " + e.getMessage();
        }
    }
}
