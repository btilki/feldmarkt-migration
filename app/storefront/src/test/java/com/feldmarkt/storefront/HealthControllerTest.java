package com.feldmarkt.storefront;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.dao.DataAccessResourceFailureException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(HealthController.class)
class HealthControllerTest {

  @Autowired private MockMvc mvc;

  @MockitoBean private JdbcTemplate jdbc;

  @Test
  void healthReturns200WhenTheDatabaseReturnsOne() throws Exception {
    when(jdbc.queryForObject("SELECT 1", Integer.class)).thenReturn(1);

    mvc.perform(get("/health")).andExpect(status().isOk()).andExpect(content().string("ok"));
  }

  @Test
  void healthReturns503WhenTheDatabaseIsDown() throws Exception {
    when(jdbc.queryForObject("SELECT 1", Integer.class))
        .thenThrow(new DataAccessResourceFailureException("down"));

    mvc.perform(get("/health")).andExpect(status().isServiceUnavailable());
  }
}
