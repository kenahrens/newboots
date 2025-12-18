package com.speedscale.newboots

import org.bson.Document
import org.springframework.boot.CommandLineRunner
import org.springframework.stereotype.Component

@Component
class InventoryInitializer(private val inventoryService: InventoryService) : CommandLineRunner {

    override fun run(vararg args: String?) {
        if (inventoryService.count() == 0L) {
            val initialInventory = listOf(
                Inventory(
                    item = "journal",
                    qty = 25,
                    size = Document(mapOf("h" to 14, "w" to 21, "uom" to "cm")),
                    status = "A"
                ),
                Inventory(
                    item = "notebook",
                    qty = 50,
                    size = Document(mapOf("h" to 8.5, "w" to 11, "uom" to "in")),
                    status = "A"
                ),
                Inventory(
                    item = "paper",
                    qty = 100,
                    size = Document(mapOf("h" to 8.5, "w" to 11, "uom" to "in")),
                    status = "D"
                ),
                Inventory(
                    item = "planner",
                    qty = 75,
                    size = Document(mapOf("h" to 22.85, "w" to 30, "uom" to "cm")),
                    status = "D"
                ),
                Inventory(
                    item = "postcard",
                    qty = 45,
                    size = Document(mapOf("h" to 10, "w" to 15.25, "uom" to "cm")),
                    status = "A"
                )
            )
            inventoryService.saveAll(initialInventory)
        }
    }
}
