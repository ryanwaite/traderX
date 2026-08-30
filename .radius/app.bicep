extension radius

param environment string

@secure()
param registryUsername string

@secure()
param databasePassword string

@secure()
param registryPassword string

resource traderxApp 'Radius.Core/applications@2025-08-01-preview' = {
  name: 'traderx'
  properties: {
    environment: environment
  }
}

resource postgresDb 'Radius.Data/postgreSqlDatabases@2025-08-01-preview' = {
  name: 'postgres'
  properties: {
    environment: environment
    application: traderxApp.id
    codeReference: 'specs/005-postgres-database-replacement/system/docker-compose.postgres.snippet.yaml#L1'
    database: 'traderx'
    initSql: '''
DROP TABLE IF EXISTS trades;
DROP TABLE IF EXISTS accountusers;
DROP TABLE IF EXISTS positions;
DROP TABLE IF EXISTS accounts;
DROP SEQUENCE IF EXISTS accounts_seq;

CREATE TABLE accounts (
  id INTEGER PRIMARY KEY,
  displayname VARCHAR(50)
);

CREATE TABLE accountusers (
  accountid INTEGER NOT NULL,
  username VARCHAR(15) NOT NULL,
  PRIMARY KEY (accountid, username),
  FOREIGN KEY (accountid) REFERENCES accounts(id)
);

CREATE TABLE positions (
  accountid INTEGER,
  security VARCHAR(15),
  updated TIMESTAMP,
  quantity INTEGER,
  PRIMARY KEY (accountid, security),
  FOREIGN KEY (accountid) REFERENCES accounts(id)
);

CREATE TABLE trades (
  id VARCHAR(50) PRIMARY KEY,
  accountid INTEGER REFERENCES accounts(id),
  created TIMESTAMP,
  updated TIMESTAMP,
  security VARCHAR(15),
  side VARCHAR(10) CHECK (side in ('Buy', 'Sell')),
  quantity INTEGER CHECK (quantity > 0),
  state VARCHAR(20) CHECK (state in ('New', 'Processing', 'Settled', 'Cancelled'))
);

CREATE SEQUENCE accounts_seq START WITH 65000 INCREMENT BY 1;

INSERT INTO accounts (id, displayname) VALUES (22214, 'Test Account 20');
INSERT INTO accounts (id, displayname) VALUES (11413, 'Private Clients Fund TTXX');
INSERT INTO accounts (id, displayname) VALUES (42422, 'Algo Execution Partners');
INSERT INTO accounts (id, displayname) VALUES (52355, 'Big Corporate Fund');
INSERT INTO accounts (id, displayname) VALUES (62654, 'Hedge Fund TXY1');
INSERT INTO accounts (id, displayname) VALUES (10031, 'Internal Trading Book');
INSERT INTO accounts (id, displayname) VALUES (44044, 'Trading Account 1');

INSERT INTO accountusers (accountid, username) VALUES (22214, 'user01');
INSERT INTO accountusers (accountid, username) VALUES (22214, 'user03');
INSERT INTO accountusers (accountid, username) VALUES (22214, 'user09');
INSERT INTO accountusers (accountid, username) VALUES (22214, 'user05');
INSERT INTO accountusers (accountid, username) VALUES (22214, 'user07');
INSERT INTO accountusers (accountid, username) VALUES (62654, 'user09');
INSERT INTO accountusers (accountid, username) VALUES (62654, 'user05');
INSERT INTO accountusers (accountid, username) VALUES (62654, 'user07');
INSERT INTO accountusers (accountid, username) VALUES (62654, 'user01');
INSERT INTO accountusers (accountid, username) VALUES (10031, 'user01');
INSERT INTO accountusers (accountid, username) VALUES (10031, 'user03');
INSERT INTO accountusers (accountid, username) VALUES (10031, 'user09');
INSERT INTO accountusers (accountid, username) VALUES (44044, 'user09');
INSERT INTO accountusers (accountid, username) VALUES (44044, 'user05');
INSERT INTO accountusers (accountid, username) VALUES (44044, 'user07');
INSERT INTO accountusers (accountid, username) VALUES (44044, 'user04');
INSERT INTO accountusers (accountid, username) VALUES (44044, 'user01');
INSERT INTO accountusers (accountid, username) VALUES (44044, 'user06');

INSERT INTO trades (id, created, updated, security, side, quantity, state, accountid) VALUES ('TRADE-22214-AABBCC', NOW(), NOW(), 'IBM', 'Sell', 100, 'Settled', 22214);
INSERT INTO trades (id, created, updated, security, side, quantity, state, accountid) VALUES ('TRADE-22214-DDEEFF', NOW(), NOW(), 'MS', 'Buy', 1000, 'Settled', 22214);
INSERT INTO trades (id, created, updated, security, side, quantity, state, accountid) VALUES ('TRADE-22214-GGHHII', NOW(), NOW(), 'C', 'Sell', 2000, 'Settled', 22214);

INSERT INTO positions (accountid, security, updated, quantity) VALUES (22214, 'MS', NOW(), 1000);
INSERT INTO positions (accountid, security, updated, quantity) VALUES (22214, 'IBM', NOW(), -100);
INSERT INTO positions (accountid, security, updated, quantity) VALUES (22214, 'C', NOW(), -2000);

INSERT INTO trades (id, created, updated, security, side, quantity, state, accountid) VALUES ('TRADE-52355-AABBCC', NOW(), NOW(), 'BAC', 'Sell', 2400, 'Settled', 52355);
INSERT INTO positions (accountid, security, updated, quantity) VALUES (52355, 'BAC', NOW(), -2400);
'''
    password: databasePassword
    size: 'S'
    username: 'traderx'
  }
}

resource redisCache 'Radius.Data/redisCaches@2025-08-01-preview' = {
  name: 'redis-cache'
  properties: {
    environment: environment
    application: traderxApp.id
    codeReference: 'specs/016-redis-database-cache/system/architecture.model.json#L46'
    size: 'S'
  }
}

resource registryCreds 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'radius-ghcr-registry-creds'
  properties: {
    environment: environment
    application: traderxApp.id
    codeReference: 'specs/004-containerized-compose-runtime/spec.md#L34'
    data: {
      password: {
        value: registryPassword
      }
      username: {
        value: registryUsername
      }
    }
  }
}

resource accountServiceImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'account-service-image'
  properties: {
    environment: environment
    application: traderxApp.id
    codeReference: 'specs/016-redis-database-cache/generation/dockerfiles/account-service.Dockerfile#L1'
    tag: '3b2f230ac244'
    build: {
      source: 'git::https://github.com/ryanwaite/traderX.git?ref=3b2f230ac2444813f46ae1ab0d139894e3d78b33'
      dockerfile: 'specs/016-redis-database-cache/generation/dockerfiles/account-service.Dockerfile'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource ingressImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'ingress-image'
  properties: {
    environment: environment
    application: traderxApp.id
    codeReference: 'specs/004-containerized-compose-runtime/system/docker-compose.spec.yaml#L141'
    tag: '5d6415e7b401'
    build: {
      source: 'git::https://github.com/ryanwaite/traderX.git//ingress?ref=5d6415e7b4011948e2b0e624c8df8218482adc37'
      dockerfile: 'Dockerfile.compose'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource peopleServiceImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'people-service-image'
  properties: {
    environment: environment
    application: traderxApp.id
    codeReference: 'specs/004-containerized-compose-runtime/system/docker-compose.spec.yaml#L43'
    tag: '5d6415e7b401'
    build: {
      source: 'git::https://github.com/ryanwaite/traderX.git//people-service?ref=5d6415e7b4011948e2b0e624c8df8218482adc37'
      dockerfile: 'Dockerfile.compose'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource positionServiceImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'position-service-image'
  properties: {
    environment: environment
    application: traderxApp.id
    codeReference: 'specs/016-redis-database-cache/generation/dockerfiles/position-service.Dockerfile#L1'
    tag: '3b2f230ac244'
    build: {
      source: 'git::https://github.com/ryanwaite/traderX.git?ref=3b2f230ac2444813f46ae1ab0d139894e3d78b33'
      dockerfile: 'specs/016-redis-database-cache/generation/dockerfiles/position-service.Dockerfile'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource referenceDataImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'reference-data-image'
  properties: {
    environment: environment
    application: traderxApp.id
    codeReference: 'specs/004-containerized-compose-runtime/system/docker-compose.spec.yaml#L19'
    tag: '5d6415e7b401'
    build: {
      source: 'git::https://github.com/ryanwaite/traderX.git//reference-data?ref=5d6415e7b4011948e2b0e624c8df8218482adc37'
      dockerfile: 'Dockerfile.compose'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource tradeFeedImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'trade-feed-image'
  properties: {
    environment: environment
    application: traderxApp.id
    codeReference: 'specs/004-containerized-compose-runtime/system/docker-compose.spec.yaml#L32'
    tag: '5d6415e7b401'
    build: {
      source: 'git::https://github.com/ryanwaite/traderX.git//trade-feed?ref=5d6415e7b4011948e2b0e624c8df8218482adc37'
      dockerfile: 'Dockerfile.compose'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource tradeProcessorImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'trade-processor-image'
  properties: {
    environment: environment
    application: traderxApp.id
    codeReference: 'specs/016-redis-database-cache/generation/dockerfiles/trade-processor.Dockerfile#L1'
    tag: '3b2f230ac244'
    build: {
      source: 'git::https://github.com/ryanwaite/traderX.git?ref=3b2f230ac2444813f46ae1ab0d139894e3d78b33'
      dockerfile: 'specs/016-redis-database-cache/generation/dockerfiles/trade-processor.Dockerfile'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource tradeServiceImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'trade-service-image'
  properties: {
    environment: environment
    application: traderxApp.id
    codeReference: 'templates/trade-service-specfirst/Dockerfile#L1'
    tag: '5d6415e7b401'
    build: {
      source: 'git::https://github.com/ryanwaite/traderX.git//trade-service?ref=5d6415e7b4011948e2b0e624c8df8218482adc37'
      dockerfile: 'Dockerfile.compose'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource webFrontEndImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'web-front-end-angular-image'
  properties: {
    environment: environment
    application: traderxApp.id
    codeReference: 'templates/web-front-end/angular/Dockerfile.prod#L1'
    tag: '5d6415e7b401'
    build: {
      source: 'git::https://github.com/ryanwaite/traderX.git//web-front-end/angular?ref=5d6415e7b4011948e2b0e624c8df8218482adc37'
      dockerfile: 'Dockerfile.compose'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource peopleServiceContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'people-service'
  properties: {
    environment: environment
    application: traderxApp.id
    codeReference: 'templates/people-service-specfirst/PeopleService.WebApi/Program.cs#L1'
    containers: {
      peopleService: {
        image: peopleServiceImage.properties.imageReference
        env: {
          CORS_ALLOWED_ORIGINS: {
            value: '*'
          }
          PEOPLE_SERVICE_PORT: {
            value: '18089'
          }
        }
        ports: {
          web: {
            containerPort: 18089
          }
        }
      }
    }
  }
}

resource accountServiceContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'account-service'
  properties: {
    environment: environment
    application: traderxApp.id
    codeReference: 'templates/account-service-specfirst/src/main/resources/application.properties#L1'
    containers: {
      accountService: {
        image: accountServiceImage.properties.imageReference
        env: {
          ACCOUNT_SERVICE_PORT: {
            value: '18088'
          }
          CACHE_ENABLED: {
            value: 'true'
          }
          CACHE_TTL: {
            value: '30s'
          }
          CORS_ALLOWED_ORIGINS: {
            value: '*'
          }
          DATABASE_DBPASS: {
            value: databasePassword
          }
          DATABASE_DBUSER: {
            value: 'traderx'
          }
          DATABASE_NAME: {
            value: 'traderx'
          }
          DATABASE_PG_HOST: {
            value: postgresDb.properties.host
          }
          DATABASE_PG_PORT: {
            value: postgresDb.properties.port
          }
          PEOPLE_SERVICE_URL: {
            value: 'http://${any(peopleServiceContainer.properties).hosts.peopleService}:18089'
          }
          REDIS_HOST: {
            value: redisCache.properties.host
          }
          REDIS_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                secretName: redisCache.properties.secrets.name
                key: 'accessKey'
              }
            }
          }
          REDIS_PORT: {
            value: string(redisCache.properties.port)
          }
          REDIS_SSL: {
            value: 'true'
          }
        }
        ports: {
          web: {
            containerPort: 18088
          }
        }
      }
    }
    connections: {
      postgresdb: {
        source: postgresDb.id
        disableDefaultEnvVars: true
      }
      redis: {
        source: redisCache.id
        disableDefaultEnvVars: true
      }
    }
  }
}

resource positionServiceContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'position-service'
  properties: {
    environment: environment
    application: traderxApp.id
    codeReference: 'templates/position-service-specfirst/src/main/resources/application.properties#L1'
    containers: {
      positionService: {
        image: positionServiceImage.properties.imageReference
        env: {
          CACHE_ENABLED: {
            value: 'true'
          }
          CACHE_TTL: {
            value: '30s'
          }
          CORS_ALLOWED_ORIGINS: {
            value: '*'
          }
          DATABASE_DBPASS: {
            value: databasePassword
          }
          DATABASE_DBUSER: {
            value: 'traderx'
          }
          DATABASE_NAME: {
            value: 'traderx'
          }
          DATABASE_PG_HOST: {
            value: postgresDb.properties.host
          }
          DATABASE_PG_PORT: {
            value: postgresDb.properties.port
          }
          POSITION_SERVICE_PORT: {
            value: '18090'
          }
          REDIS_HOST: {
            value: redisCache.properties.host
          }
          REDIS_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                secretName: redisCache.properties.secrets.name
                key: 'accessKey'
              }
            }
          }
          REDIS_PORT: {
            value: string(redisCache.properties.port)
          }
          REDIS_SSL: {
            value: 'true'
          }
        }
        ports: {
          web: {
            containerPort: 18090
          }
        }
      }
    }
    connections: {
      postgresdb: {
        source: postgresDb.id
        disableDefaultEnvVars: true
      }
      redis: {
        source: redisCache.id
        disableDefaultEnvVars: true
      }
    }
  }
}

resource referenceDataContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'reference-data'
  properties: {
    environment: environment
    application: traderxApp.id
    codeReference: 'templates/reference-data-specfirst/src/main.ts#L1'
    containers: {
      referenceData: {
        image: referenceDataImage.properties.imageReference
        env: {
          CORS_ALLOWED_ORIGINS: {
            value: '*'
          }
          REFERENCE_DATA_SERVICE_PORT: {
            value: '18085'
          }
        }
        ports: {
          web: {
            containerPort: 18085
          }
        }
      }
    }
  }
}

resource tradeFeedContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'trade-feed'
  properties: {
    environment: environment
    application: traderxApp.id
    codeReference: 'templates/trade-feed-specfirst/index.js#L1'
    containers: {
      tradeFeed: {
        image: tradeFeedImage.properties.imageReference
        env: {
          CORS_ALLOWED_ORIGINS: {
            value: '*'
          }
          TRADE_FEED_PORT: {
            value: '18086'
          }
        }
        ports: {
          web: {
            containerPort: 18086
          }
        }
      }
    }
  }
}

resource tradeProcessorContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'trade-processor'
  properties: {
    environment: environment
    application: traderxApp.id
    codeReference: 'templates/trade-processor-specfirst/src/main/resources/application.properties#L1'
    containers: {
      tradeProcessor: {
        image: tradeProcessorImage.properties.imageReference
        env: {
          CACHE_ENABLED: {
            value: 'true'
          }
          CACHE_TTL: {
            value: '30s'
          }
          CORS_ALLOWED_ORIGINS: {
            value: '*'
          }
          DATABASE_DBPASS: {
            value: databasePassword
          }
          DATABASE_DBUSER: {
            value: 'traderx'
          }
          DATABASE_NAME: {
            value: 'traderx'
          }
          DATABASE_PG_HOST: {
            value: postgresDb.properties.host
          }
          DATABASE_PG_PORT: {
            value: postgresDb.properties.port
          }
          REDIS_HOST: {
            value: redisCache.properties.host
          }
          REDIS_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                secretName: redisCache.properties.secrets.name
                key: 'accessKey'
              }
            }
          }
          REDIS_PORT: {
            value: string(redisCache.properties.port)
          }
          REDIS_SSL: {
            value: 'true'
          }
          TRADE_FEED_ADDRESS: {
            value: 'http://${any(tradeFeedContainer.properties).hosts.tradeFeed}:18086'
          }
          TRADE_PROCESSOR_SERVICE_PORT: {
            value: '18091'
          }
        }
        ports: {
          web: {
            containerPort: 18091
          }
        }
      }
    }
    connections: {
      postgresdb: {
        source: postgresDb.id
        disableDefaultEnvVars: true
      }
      redis: {
        source: redisCache.id
        disableDefaultEnvVars: true
      }
    }
  }
}

resource tradeServiceContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'trade-service'
  properties: {
    environment: environment
    application: traderxApp.id
    codeReference: 'templates/trade-service-specfirst/src/main/resources/application.properties#L1'
    containers: {
      tradeService: {
        image: tradeServiceImage.properties.imageReference
        env: {
          ACCOUNT_SERVICE_URL: {
            value: 'http://${any(accountServiceContainer.properties).hosts.accountService}:18088'
          }
          CORS_ALLOWED_ORIGINS: {
            value: '*'
          }
          PEOPLE_SERVICE_URL: {
            value: 'http://${any(peopleServiceContainer.properties).hosts.peopleService}:18089'
          }
          REFERENCE_DATA_SERVICE_URL: {
            value: 'http://${any(referenceDataContainer.properties).hosts.referenceData}:18085'
          }
          TRADE_FEED_ADDRESS: {
            value: 'http://${any(tradeFeedContainer.properties).hosts.tradeFeed}:18086'
          }
          TRADING_SERVICE_PORT: {
            value: '18092'
          }
        }
        ports: {
          web: {
            containerPort: 18092
          }
        }
      }
    }
  }
}

resource webFrontEndContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'web-front-end-angular'
  properties: {
    environment: environment
    application: traderxApp.id
    codeReference: 'templates/web-front-end/angular/main/main.ts#L1'
    containers: {
      webFrontEnd: {
        image: webFrontEndImage.properties.imageReference
        env: {
          WEB_SERVICE_PORT: {
            value: '18093'
          }
        }
        ports: {
          web: {
            containerPort: 18093
          }
        }
      }
    }
  }
}

resource ingressContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'ingress'
  properties: {
    environment: environment
    application: traderxApp.id
    codeReference: 'specs/004-containerized-compose-runtime/system/ingress-nginx.conf.template#L1'
    containers: {
      ingress: {
        image: ingressImage.properties.imageReference
        env: {
          ACCOUNT_SERVICE_URL: {
            value: 'http://${any(accountServiceContainer.properties).hosts.accountService}:18088/'
          }
          DATABASE_URL: {
            value: 'http://${postgresDb.properties.host}:${postgresDb.properties.port}/'
          }
          NGINX_HOST: {
            value: 'localhost'
          }
          PEOPLE_SERVICE_URL: {
            value: 'http://${any(peopleServiceContainer.properties).hosts.peopleService}:18089/'
          }
          POSITION_SERVICE_URL: {
            value: 'http://${any(positionServiceContainer.properties).hosts.positionService}:18090/'
          }
          REFERENCE_DATA_URL: {
            value: 'http://${any(referenceDataContainer.properties).hosts.referenceData}:18085/'
          }
          TRADE_FEED_URL: {
            value: 'http://${any(tradeFeedContainer.properties).hosts.tradeFeed}:18086/'
          }
          TRADE_PROCESSOR_URL: {
            value: 'http://${any(tradeProcessorContainer.properties).hosts.tradeProcessor}:18091/'
          }
          TRADE_SERVICE_URL: {
            value: 'http://${any(tradeServiceContainer.properties).hosts.tradeService}:18092/'
          }
          WEB_FRONTEND_URL: {
            value: 'http://${any(webFrontEndContainer.properties).hosts.webFrontEnd}:18093/'
          }
        }
        ports: {
          web: {
            containerPort: 8080
          }
        }
      }
    }
  }
}

resource ingressRoute 'Radius.Compute/routes@2025-08-01-preview' = {
  name: 'ingress'
  properties: {
    environment: environment
    application: traderxApp.id
    codeReference: 'specs/004-containerized-compose-runtime/system/docker-compose.spec.yaml#L157'
    kind: 'HTTP'
    rules: [
      {
        matches: [
          {
            httpPath: '/'
          }
        ]
        destinationContainer: {
          resourceId: ingressContainer.id
          containerName: 'ingress'
          containerPort: 8080
        }
      }
    ]
  }
}
