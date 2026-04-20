package com.example.gateway;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.PostConstruct;

@RestController
@RequestMapping("/")
public class GatewayController {

    // 注入环境标识
    @Value("${app.environment:UNKNOWN}")
    private String environment;
    
    @Value("${app.environment-name:未知环境}")
    private String environmentName;

    /**
     * 服务启动时打印醒目的环境标识
     */
    @PostConstruct
    public void init() {
        System.out.println("=================================================");
        System.out.println("===  网关服务启动 - 当前环境: [" + environment + "] " + environmentName + "  ===");
        System.out.println("=================================================");
    }

    @GetMapping("/health")
    public String health() {
        return "Gateway Service is UP | Environment: [" + environment + "] " + environmentName;
    }
}