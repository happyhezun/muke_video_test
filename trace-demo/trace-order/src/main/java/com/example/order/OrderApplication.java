package com.example.order;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.core.env.Environment;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.servlet.mvc.method.RequestMappingInfo;
import org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping;

import java.net.InetAddress;
import java.util.Map;
import java.util.Set;

@SpringBootApplication
public class OrderApplication {

    public static void main(String[] args) {
        SpringApplication.run(OrderApplication.class, args);
    }

    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }

    // 新增: 启动时打印所有注册的 API 接口及端口，用于排查 404 问题
    @Bean
    public CommandLineRunner commandLineRunner(ApplicationContext ctx, Environment env) {
        return args -> {
            String port = env.getProperty("local.server.port");
            // 增加对 server.port 的直接获取，以防 local.server.port 在某些容器环境下不准确
            String configuredPort = env.getProperty("server.port", "8080");
            String hostAddress = InetAddress.getLocalHost().getHostAddress();
            
            System.out.println("==========================================================");
            System.out.println("Order Application is running!");
            System.out.println("Configured Port: " + configuredPort);
            System.out.println("Actual Local Port: " + port);
            System.out.println("Local Access: \t\thttp://localhost:" + port + "/order/create");
            System.out.println("External Access: \thttp://" + hostAddress + ":" + port + "/order/create");
            System.out.println("==========================================================");

            System.out.println("Registered API Endpoints:");
            RequestMappingHandlerMapping mapping = ctx.getBean(RequestMappingHandlerMapping.class);
            Map<RequestMappingInfo, ? extends Object> map = mapping.getHandlerMethods();
            Set<RequestMappingInfo> keys = map.keySet();
            for (RequestMappingInfo key : keys) {
                // 更清晰的打印格式
                System.out.println("  -> " + key.getPatternsCondition());
            }
            System.out.println("==========================================================");
        };
    }
}