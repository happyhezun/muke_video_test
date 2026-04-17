package com.example.trace.controller; // 请根据你的实际包名调整

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cloud.client.loadbalancer.LoadBalanced;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

@RestController
@RequestMapping("/order")
public class OrderController {

    @Autowired
    private RestTemplate restTemplate;

    /**
     * 创建订单接口
     * 路径：/order/create
     * 调用方：Gateway -> Order -> Inventory
     */
    @GetMapping("/create")
    public String createOrder(@RequestParam String orderId) {
        System.out.println(">>> [Order Service] 开始处理订单: " + orderId);

        // ==========================================
        // 关键修改点：
        // 1. 不要写死 http://localhost:8082
        // 2. 使用服务名 http://trace-inventory
        // ==========================================
        String inventoryServiceUrl = "http://trace-inventory/inventory/deduct";
        
        // 构建完整 URL (包含参数)
        // 注意：这里假设你的库存服务名在 application.yml 中配置为 trace-inventory
        String url = inventoryServiceUrl + "?productId=P_" + orderId;

        try {
            // 调用库存服务
            // 因为有 @LoadBalanced，RestTemplate 会自动把 trace-inventory 解析为具体的 IP:Port
            String result = restTemplate.getForObject(url, String.class);
            
            System.out.println(">>> [Order Service] 库存扣减成功: " + result);
            return "订单 " + orderId + " 处理完成，结果：" + result;
            
        } catch (Exception e) {
            e.printStackTrace();
            return "订单 " + orderId + " 处理失败，原因：" + e.getMessage();
        }
    }
}