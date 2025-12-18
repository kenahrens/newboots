package com.speedscale.newboots

import com.mongodb.client.model.Filters
import com.mongodb.kotlin.client.coroutine.MongoDatabase
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.runBlocking
import org.springframework.stereotype.Service

@Service
class InventoryService(private val mongoDatabase: MongoDatabase) {

    private val collection = mongoDatabase.getCollection<Inventory>("inventory")

    fun count(): Long = runBlocking {
        collection.countDocuments()
    }

    fun saveAll(inventories: List<Inventory>): List<Inventory> = runBlocking {
        collection.insertMany(inventories)
        inventories
    }

    fun findAll(): List<Inventory> = runBlocking {
        collection.find().toList()
    }

    fun find(key: String, value: Any): List<Inventory> = runBlocking {
        collection.find(Filters.eq(key, value)).toList()
    }
}
