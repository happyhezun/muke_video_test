package com.example.inventory;

// --- 添加下面这些导入语句 ---
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
// -------------------------

@RestController
@RequestMapping("/inventory")
public class InventoryController {

    @GetMapping("/deduct")
    public String deductStock(@RequestParam String productId) {
        // 模拟业务处理耗时
        try { Thread.sleep(200); } catch (Exception e) {} 
        return "库存扣减成功: " + productId;
    }
}