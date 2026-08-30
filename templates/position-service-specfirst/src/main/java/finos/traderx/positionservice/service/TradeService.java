package finos.traderx.positionservice.service;

import finos.traderx.positionservice.model.Trade;
import finos.traderx.positionservice.repository.TradeRepository;
import java.util.List;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

@Service
public class TradeService {

  private final TradeRepository tradeRepository;

  public TradeService(TradeRepository tradeRepository) {
    this.tradeRepository = tradeRepository;
  }

  @Cacheable("trades")
  public List<Trade> getAllTrades() {
    return tradeRepository.findAll();
  }

  @Cacheable(cacheNames = "tradesByAccount", key = "#accountId")
  public List<Trade> getTradesByAccountID(int accountId) {
    return tradeRepository.findByAccountId(accountId);
  }
}
