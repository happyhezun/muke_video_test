package com.demo;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
public class PayApplication {
    public static void main(String[] args) {
        SpringApplication.run(PayApplication.class, args);
    }
}

@RestController
class PayController {
    private static final Logger log = LoggerFactory.getLogger(PayController.class);

    @GetMapping("/pay/exec")
    public String execute() throws InterruptedException {
        log.info(">>>> [Pay Service] 接收到支付请求，正在处理...");
        Thread.sleep(500); // 模拟业务耗时
        log.info(">>>> [Pay Service] 支付处理完成。");
        return "Payment Success (Trace ID 自动传递)";
    }
}

