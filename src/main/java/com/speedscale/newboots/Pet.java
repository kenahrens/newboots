package com.speedscale.newboots;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/** Pet entity representing a pet breed stored in MySQL. */
@Entity
@Table(name = "pets")
public final class Pet {
  /** The unique identifier for the pet. */
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  /** The breed name of the pet. */
  @Column(name = "breed", nullable = false)
  private String breed;

  /** The species of the pet (e.g., Dog, Cat). */
  @Column(name = "species", nullable = false)
  private String species;

  /** Description of the pet breed. */
  @Column(name = "description")
  private String description;

  /** Average lifespan in years. */
  @Column(name = "average_lifespan")
  private Integer averageLifespan;

  /** Size category (Small, Medium, Large). */
  @Column(name = "size_category")
  private String sizeCategory;

  /** Default constructor. */
  public Pet() {}

  /**
   * Constructor with all fields.
   *
   * @param breed the breed name
   * @param species the species
   * @param description the description
   * @param averageLifespan the average lifespan
   * @param sizeCategory the size category
   */
  public Pet(
      final String breed,
      final String species,
      final String description,
      final Integer averageLifespan,
      final String sizeCategory) {
    this.breed = breed;
    this.species = species;
    this.description = description;
    this.averageLifespan = averageLifespan;
    this.sizeCategory = sizeCategory;
  }

  /**
   * Gets the ID.
   *
   * @return the ID
   */
  public Long getId() {
    return id;
  }

  /**
   * Sets the ID.
   *
   * @param id the ID to set
   */
  public void setId(final Long id) {
    this.id = id;
  }

  /**
   * Gets the breed.
   *
   * @return the breed
   */
  public String getBreed() {
    return breed;
  }

  /**
   * Sets the breed.
   *
   * @param breed the breed to set
   */
  public void setBreed(final String breed) {
    this.breed = breed;
  }

  /**
   * Gets the species.
   *
   * @return the species
   */
  public String getSpecies() {
    return species;
  }

  /**
   * Sets the species.
   *
   * @param species the species to set
   */
  public void setSpecies(final String species) {
    this.species = species;
  }

  /**
   * Gets the description.
   *
   * @return the description
   */
  public String getDescription() {
    return description;
  }

  /**
   * Sets the description.
   *
   * @param description the description to set
   */
  public void setDescription(final String description) {
    this.description = description;
  }

  /**
   * Gets the average lifespan.
   *
   * @return the average lifespan
   */
  public Integer getAverageLifespan() {
    return averageLifespan;
  }

  /**
   * Sets the average lifespan.
   *
   * @param averageLifespan the average lifespan to set
   */
  public void setAverageLifespan(final Integer averageLifespan) {
    this.averageLifespan = averageLifespan;
  }

  /**
   * Gets the size category.
   *
   * @return the size category
   */
  public String getSizeCategory() {
    return sizeCategory;
  }

  /**
   * Sets the size category.
   *
   * @param sizeCategory the size category to set
   */
  public void setSizeCategory(final String sizeCategory) {
    this.sizeCategory = sizeCategory;
  }
}
