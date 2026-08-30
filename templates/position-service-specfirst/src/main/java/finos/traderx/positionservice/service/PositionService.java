package finos.traderx.positionservice.service;

import finos.traderx.positionservice.model.Position;
import finos.traderx.positionservice.repository.PositionRepository;
import java.util.List;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

@Service
public class PositionService {

  private final PositionRepository positionRepository;

  public PositionService(PositionRepository positionRepository) {
    this.positionRepository = positionRepository;
  }

  @Cacheable("positions")
  public List<Position> getAllPositions() {
    return positionRepository.findAll();
  }

  @Cacheable(cacheNames = "positionsByAccount", key = "#accountId")
  public List<Position> getPositionsByAccountID(int accountId) {
    return positionRepository.findByAccountId(accountId);
  }
}
