package com.example.gateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class GatewayApplication {

    public static void main(String[] args) {
        SpringApplication.run(GatewayApplication.class, args);
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