package bawag.at.demo_clicker;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.ResponseBody;

@Controller
public class ClickCounterController {
    
    private int counter = 0;
    
    @GetMapping("/")
    public String index() {
        return "index";  // Returns the Thymeleaf template
    }
    
    @PostMapping("/click")
    @ResponseBody  // This tells Spring to return JSON, not look for a template
    public ClickCount incrementCounter() {
        counter++;
        return new ClickCount(counter);
    }
    
    @GetMapping("/count")
    @ResponseBody  // This tells Spring to return JSON, not look for a template
    public ClickCount getCount() {
        return new ClickCount(counter);
    }

    @PostMapping("/reset")
    @ResponseBody
    public ClickCount resetCounter() {
        counter = 0;
        return new ClickCount(counter);
    }
}
