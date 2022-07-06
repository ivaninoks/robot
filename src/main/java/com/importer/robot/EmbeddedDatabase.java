package com.importer.robot;

import org.testcontainers.containers.*;

import java.io.*;

class EmbeddedDatabase implements Closeable {
    private final PostgreSQLContainer<?> postgreSQLContainer;

    EmbeddedDatabase() {
        postgreSQLContainer = new PostgreSQLContainer<>();
        postgreSQLContainer.start();
    }

    String username() {
        return postgreSQLContainer.getUsername();
    }

    String password() {
        return postgreSQLContainer.getPassword();
    }

    String url() {
        return postgreSQLContainer.getJdbcUrl();
    }

    @Override
    public void close() throws IOException {
        postgreSQLContainer.stop();
    }
}
