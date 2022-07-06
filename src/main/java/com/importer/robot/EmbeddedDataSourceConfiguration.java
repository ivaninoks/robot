package com.importer.robot;

import com.importer.robot.model.*;
import lombok.*;
import lombok.extern.slf4j.*;
import org.springframework.boot.autoconfigure.condition.*;
import org.springframework.boot.autoconfigure.jdbc.*;
import org.springframework.boot.orm.jpa.*;
import org.springframework.context.annotation.*;
import org.springframework.data.jpa.repository.config.*;
import org.springframework.orm.jpa.*;

import javax.sql.*;

@Slf4j
@Configuration
@RequiredArgsConstructor
@EnableJpaRepositories(basePackageClasses = {FileEntity.class},
        entityManagerFactoryRef = "embeddedDataSourceEntityManagerFactory")
@ConditionalOnProperty(prefix = "spring.datasource", name = "embedded", havingValue = "true", matchIfMissing = true)
public class EmbeddedDataSourceConfiguration {

    private final DataSourceProperties dataSourceProperties;

    @Primary
    @Bean
    DataSource primaryDataSource(EmbeddedDatabase database) {
        dataSourceProperties.setPassword(database.password());
        dataSourceProperties.setUsername(database.username());
        dataSourceProperties.setUrl(database.url());
        log.warn("Starting embedded database: {}; {}:{}", database.url(), database.username(), database.password());
        return dataSourceProperties.initializeDataSourceBuilder().build();
    }

    @Bean
    EmbeddedDatabase embeddedDatabase() {
        return new EmbeddedDatabase();
    }

    @Primary
    @Bean("embeddedDataSourceEntityManagerFactory")
    LocalContainerEntityManagerFactoryBean embeddedDataSourceEntityManagerFactory(EntityManagerFactoryBuilder builder) {
        return builder
                .dataSource(primaryDataSource(embeddedDatabase()))
                .packages(FileEntity.class)
                .build();
    }
}
