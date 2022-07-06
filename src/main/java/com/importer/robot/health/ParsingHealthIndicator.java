package com.importer.robot.health;

import com.importer.robot.model.*;
import lombok.*;
import org.springframework.boot.actuate.health.*;
import org.springframework.stereotype.*;

import java.util.*;

import static java.lang.String.*;
import static java.util.stream.Collectors.*;

@RequiredArgsConstructor
@Component
public class ParsingHealthIndicator extends AbstractHealthIndicator {
    private final FileRepository repository;

    @Override
    protected void doHealthCheck(Health.Builder builder) {
        List<Long> notParsed = repository.notParsedWithinTenMinutes();

        if (notParsed.isEmpty()) {
            builder.up();
        } else {
            String idString = notParsed.stream()
                    .map(String::valueOf)
                    .collect(joining(", "));

            builder.down()
                    .withDetail("message", format("Building block feeds %s are not parsed", idString));
        }
    }
}
