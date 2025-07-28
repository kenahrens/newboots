package com.speedscale.newboots;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;

/**
 * Repository interface for Pet entities.
 */
@Repository
public interface PetRepository extends JpaRepository<Pet, Long> {

    /**
     * Find pets by breed name (case-insensitive).
     *
     * @param breed the breed name to search for
     * @return list of pets matching the breed
     */
    List<Pet> findByBreedContainingIgnoreCase(String breed);

    /**
     * Find pets by species.
     *
     * @param species the species to search for
     * @return list of pets matching the species
     */
    List<Pet> findBySpecies(String species);

    /**
     * Find pets by species (case-insensitive).
     *
     * @param species the species to search for
     * @return list of pets matching the species
     */
    List<Pet> findBySpeciesIgnoreCase(String species);

    /**
     * Find pets by breed and species.
     *
     * @param breed the breed name to search for
     * @param species the species to search for
     * @return list of pets matching both criteria
     */
    List<Pet> findByBreedContainingIgnoreCaseAndSpecies(String breed,
                                                        String species);

    /**
     * Custom query to find pets by breed with more flexible matching.
     *
     * @param breed the breed pattern to search for
     * @return list of pets matching the breed pattern
     */
    @Query("SELECT p FROM Pet p WHERE LOWER(p.breed) LIKE "
           + "LOWER(CONCAT('%', :breed, '%'))")
    List<Pet> findPetsByBreedPattern(@Param("breed") String breed);
} 