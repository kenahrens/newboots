package com.speedscale.newboots

import org.bson.Document
import org.bson.codecs.pojo.annotations.BsonId
import org.bson.types.ObjectId

data class Inventory(
    @BsonId
    val id: ObjectId? = null,
    val item: String,
    val qty: Int,
    val size: Document,
    val status: String
)
