package com.feldmarkt.storefront;

import org.springframework.dao.DataAccessException;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {

  private final JdbcTemplate jdbc;

  public HealthController(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @GetMapping("/health")
  public ResponseEntity<String> health() {
    try {
      Integer one = jdbc.queryForObject("SELECT 1", Integer.class);
      if (one != null && one == 1) {
        return ResponseEntity.ok("ok");
      }
      return ResponseEntity.status(503).body("db");
    } catch (DataAccessException ex) {
      return ResponseEntity.status(503).body("db");
    }
  }
}
