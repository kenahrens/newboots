package com.speedscale.newboots;

import java.util.Map;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Document(collection = "inventory")
public class Inventory {
  @Id private String id;
  private String item;
  private int qty;
  private Map<String, Object> size;
  private String status;

  public Inventory() {}

  public Inventory(String item, int qty, Map<String, Object> size, String status) {
    this.item = item;
    this.qty = qty;
    this.size = size;
    this.status = status;
  }

  public String getId() {
    return id;
  }

  public void setId(String id) {
    this.id = id;
  }

  public String getItem() {
    return item;
  }

  public void setItem(String item) {
    this.item = item;
  }

  public int getQty() {
    return qty;
  }

  public void setQty(int qty) {
    this.qty = qty;
  }

  public Map<String, Object> getSize() {
    return size;
  }

  public void setSize(Map<String, Object> size) {
    this.size = size;
  }

  public String getStatus() {
    return status;
  }

  public void setStatus(String status) {
    this.status = status;
  }
}
