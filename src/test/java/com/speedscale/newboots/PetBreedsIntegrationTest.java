package com.speedscale.newboots;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.Arrays;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

/** Integration test for pet breeds endpoint. */
@WebMvcTest(NewController.class)
public final class PetBreedsIntegrationTest {

  /** Mock MVC for testing. */
  @Autowired private MockMvc mockMvc;

  /** Mock pet repository. */
  @MockBean private PetRepository petRepository;

  /** Mock inventory service. */
  @MockBean private InventoryService inventoryService;

  /** Mock reactive API helper. */
  @MockBean private ReactiveApiHelper reactiveApiHelper;

  /** Mock NASA rate limiter. */
  @MockBean private NasaRateLimiter nasaRateLimiter;

  @Test
  public void testGetAllPetBreeds() throws Exception {
    List<Pet> samplePets = Arrays.asList(
        new Pet("Golden Retriever", "Dog",
                "Friendly and intelligent family dog", 12, "Large"),
        new Pet("Persian", "Cat", "Long-haired cat with a sweet personality",
                15, "Medium"));
    when(petRepository.findAll()).thenReturn(samplePets);

    mockMvc.perform(get("/pets/types"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$").isArray())
        .andExpect(jsonPath("$[0].breed").value("Golden Retriever"))
        .andExpect(jsonPath("$[1].breed").value("Persian"));
  }

  @Test
  public void testGetPetBreedsByType() throws Exception {
    List<Pet> dogPets = Arrays.asList(
        new Pet("Golden Retriever", "Dog",
                "Friendly and intelligent family dog", 12, "Large"),
        new Pet("Labrador Retriever", "Dog",
                "Popular family companion and working dog", 12, "Large"));
    when(petRepository.findBySpeciesIgnoreCase("dog")).thenReturn(dogPets);

    mockMvc.perform(get("/pets/types").param("type", "dog"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$").isArray())
        .andExpect(jsonPath("$[0].species").value("Dog"))
        .andExpect(jsonPath("$[1].species").value("Dog"));
  }

  @Test
  public void testGetPetBreedsByTypeCaseInsensitive() throws Exception {
    List<Pet> dogPets = Arrays.asList(
        new Pet("Golden Retriever", "Dog",
                "Friendly and intelligent family dog", 12, "Large"));
    when(petRepository.findBySpeciesIgnoreCase("DOG")).thenReturn(dogPets);

    mockMvc.perform(get("/pets/types").param("type", "DOG"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$").isArray())
        .andExpect(jsonPath("$[0].species").value("Dog"));
  }
}
