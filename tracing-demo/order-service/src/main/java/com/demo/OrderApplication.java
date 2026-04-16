package com.demo;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

@SpringBootApplication
public class OrderApplication {
    public static void main(String[] args) {
        SpringApplication.run(OrderApplication.class, args);
    }

    @Bean
    public RestTemplate restTemplate(RestTemplateBuilder builder) {
        return builder.build();
    }
}

@RestController
class OrderController {
    private static final Logger log = LoggerFactory.getLogger(OrderController.class);
    private final RestTemplate restTemplate;

    public OrderController(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    @GetMapping("/order/create")
    public String create() {
        log.info(">>>> [Order Service] 准备创建订单，开始调用支付服务...");
        // 调用 Pay Service
        String response = restTemplate.getForObject("http://localhost:8082/pay/exec", String.class);
        log.info(">>>> [Order Service] 支付服务返回结果: {}", response);
        return "Order Created with: " + response;
    }
}

