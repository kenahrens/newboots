package com.speedscale.newboots;

import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.beans.factory.annotation.Autowired;
import java.util.*;

@Component
public class InventoryInitializer implements CommandLineRunner {
    @Autowired
    private InventoryRepository inventoryRepository;

    @Override
    public void run(String... args) {
        if (inventoryRepository.count() == 0) {
            List<Inventory> initialInventory = new ArrayList<>();
            initialInventory.add(new Inventory("journal", 25, Map.of("h", 14, "w", 21, "uom", "cm"), "A"));
            initialInventory.add(new Inventory("notebook", 50, Map.of("h", 8.5, "w", 11, "uom", "in"), "A"));
            initialInventory.add(new Inventory("paper", 100, Map.of("h", 8.5, "w", 11, "uom", "in"), "D"));
            initialInventory.add(new Inventory("planner", 75, Map.of("h", 22.85, "w", 30, "uom", "cm"), "D"));
            initialInventory.add(new Inventory("postcard", 45, Map.of("h", 10, "w", 15.25, "uom", "cm"), "A"));
            inventoryRepository.saveAll(initialInventory);
        }
    }
} 