package com.speedscale.newboots

import com.mongodb.ConnectionString
import com.mongodb.MongoClientSettings
import com.mongodb.kotlin.client.coroutine.MongoClient
import com.mongodb.kotlin.client.coroutine.MongoDatabase
import org.bson.codecs.configuration.CodecRegistries
import org.bson.codecs.pojo.PojoCodecProvider
import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

@Configuration
open class MongoConfig {
    @Value("\${spring.data.mongodb.uri:mongodb://localhost:27017/newboots}")
    private lateinit var mongoUri: String

    @Bean
    open fun mongoClient(): MongoClient {
        val connectionString = ConnectionString(mongoUri)
        val pojoCodecProvider = PojoCodecProvider.builder()
            .automatic(true)
            .build()
        val codecRegistry = CodecRegistries.fromRegistries(
            MongoClientSettings.getDefaultCodecRegistry(),
            CodecRegistries.fromProviders(pojoCodecProvider)
        )
        val settings = MongoClientSettings.builder()
            .applyConnectionString(connectionString)
            .codecRegistry(codecRegistry)
            .build()
        return MongoClient.create(settings)
    }

    @Bean
    open fun mongoDatabase(mongoClient: MongoClient): MongoDatabase {
        val connectionString = ConnectionString(mongoUri)
        val databaseName = connectionString.database ?: "newboots"
        return mongoClient.getDatabase(databaseName)
    }
}
