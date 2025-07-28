package com.speedscale.newboots;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.Arrays;
import java.util.List;

/**
 * Initializes the pets table with sample data.
 */
@Component
public final class PetInitializer implements CommandLineRunner {

    /** Logger for this class. */
    private static final Logger LOGGER =
        LoggerFactory.getLogger(PetInitializer.class);

    /** Repository for pet operations. */
    @Autowired
    private PetRepository petRepository;

    /**
     * Runs the initialization logic.
     *
     * @param args command line arguments
     * @throws Exception if initialization fails
     */
    @Override
    public void run(final String... args) throws Exception {
        // Only initialize if the pets table is empty
        if (petRepository.count() == 0) {
            LOGGER.info("Initializing pets table with sample data...");

            List<Pet> samplePets = Arrays.asList(
                new Pet("Golden Retriever", "Dog", "Friendly and intelligent family dog", 12, "Large"),
                new Pet("Labrador Retriever", "Dog", "Popular family companion and working dog", 12, "Large"),
                new Pet("German Shepherd", "Dog", "Loyal and protective working dog", 10, "Large"),
                new Pet("Persian", "Cat", "Long-haired cat with a sweet personality", 15, "Medium"),
                new Pet("Siamese", "Cat", "Vocal and intelligent cat breed", 15, "Medium"),
                new Pet("Maine Coon", "Cat", "Large, gentle giant of the cat world", 13, "Large"),
                new Pet("Budgerigar", "Bird", "Small, colorful parakeet", 8, "Small"),
                new Pet("Cockatiel", "Bird", "Friendly and social parrot", 15, "Small"),
                new Pet("African Grey", "Bird", "Highly intelligent talking parrot", 50, "Medium"),
                new Pet("Syrian Hamster", "Rodent", "Popular small pet hamster", 3, "Small"),
                new Pet("Guinea Pig", "Rodent", "Social and gentle small pet", 6, "Small"),
                new Pet("Bearded Dragon", "Reptile", "Docile and easy-to-care-for lizard", 10, "Medium")
            );

            petRepository.saveAll(samplePets);
            LOGGER.info("Successfully initialized pets table with {} "
                + "sample records", samplePets.size());
        } else {
            LOGGER.info("Pets table already contains data, "
                + "skipping initialization");
        }
    }
} 