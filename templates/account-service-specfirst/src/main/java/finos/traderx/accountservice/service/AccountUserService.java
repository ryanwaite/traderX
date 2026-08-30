package finos.traderx.accountservice.service;

import finos.traderx.accountservice.exceptions.ResourceNotFoundException;
import finos.traderx.accountservice.model.AccountUser;
import finos.traderx.accountservice.repository.AccountRepository;
import finos.traderx.accountservice.repository.AccountUserRepository;
import java.util.List;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.CachePut;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.annotation.Caching;
import org.springframework.stereotype.Service;

@Service
public class AccountUserService {

  private final AccountUserRepository accountUserRepository;
  private final AccountRepository accountRepository;

  public AccountUserService(
      AccountUserRepository accountUserRepository,
      AccountRepository accountRepository
  ) {
    this.accountUserRepository = accountUserRepository;
    this.accountRepository = accountRepository;
  }

  @Cacheable("accountUsers")
  public List<AccountUser> getAllAccountUsers() {
    return accountUserRepository.findAll();
  }

  @Cacheable(cacheNames = "accountUserById", key = "#id")
  public AccountUser getAccountUserById(int id) {
    return accountUserRepository.findByAccountId(id)
        .orElseThrow(() -> new ResourceNotFoundException("AccountUser with id " + id + " not found"));
  }

  @Caching(
      put = @CachePut(cacheNames = "accountUserById", key = "#result.accountId"),
      evict = @CacheEvict(cacheNames = "accountUsers", allEntries = true))
  public AccountUser upsertAccountUser(AccountUser accountUser) {
    if (accountUser.getAccountId() == null || !accountRepository.existsById(accountUser.getAccountId())) {
      throw new ResourceNotFoundException("Account with id " + accountUser.getAccountId() + " not found");
    }
    return accountUserRepository.save(accountUser);
  }
}
