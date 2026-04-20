package com.example.order;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.core.env.Environment;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.servlet.mvc.method.RequestMappingInfo;
import org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping;

import javax.annotation.PostConstruct;
import java.net.InetAddress;
import java.util.Map;
import java.util.Set;

@SpringBootApplication
public class OrderApplication {

    private static final Logger log = LoggerFactory.getLogger(OrderApplication.class);

    // 注入环境标识
    @Value("${app.environment:UNKNOWN}")
    private String environment;
    
    @Value("${app.environment-name:未知环境}")
    private String environmentName;

    public static void main(String[] args) {
        SpringApplication.run(OrderApplication.class, args);
    }

    /**
     * 服务启动时打印醒目的环境标识
     */
    @PostConstruct
    public void init() {
        log.info("=================================================");
        log.info("===  订单服务启动 - 当前环境: [{}] {}  ===", environment, environmentName);
        log.info("=================================================");
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
            System.out.println("Environment: [" + environment + "] " + environmentName);
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
