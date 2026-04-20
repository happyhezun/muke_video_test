package com.example.gateway;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;

import javax.annotation.PostConstruct;

@SpringBootApplication
public class GatewayApplication {

    private static final Logger log = LoggerFactory.getLogger(GatewayApplication.class);

    // 注入环境标识
    @Value("${app.environment:UNKNOWN}")
    private String environment;
    
    @Value("${app.environment-name:未知环境}")
    private String environmentName;

    public static void main(String[] args) {
        SpringApplication.run(GatewayApplication.class, args);
    }

    /**
     * 服务启动时打印醒目的环境标识
     */
    @PostConstruct
    public void init() {
        log.info("=================================================");
        log.info("===  网关服务启动 - 当前环境: [{}] {}  ===", environment, environmentName);
        log.info("=================================================");
    }

    /**
     * 配置路由规则
     */
    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
                .route("order-service", r -> r.path("/order/**")
                        .uri("http://localhost:8081")) 
                // 修改: 移除 StripPrefix 过滤器，确保外部访问路径与内部调用路径一致
                // 外部请求 /inventory/check 将直接转发到 http://localhost:8082/inventory/check
                // 这样 OrderService 内部直接调用 http://localhost:8082/inventory/check 也能正常工作
                .route("inventory-service", r -> r.path("/inventory/**")
                        .uri("http://localhost:8082")) 
                .build();
    }

}
