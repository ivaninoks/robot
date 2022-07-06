package com.importer.robot.parse;

import com.importer.robot.model.*;
import lombok.*;
import org.springframework.scheduling.annotation.*;
import org.springframework.stereotype.*;

@Component
@RequiredArgsConstructor
public class ParsingScheduler {

    private final FileRepository repository;

    @Scheduled(fixedRate = 1000)
    public void parseImportFile() {
        repository.latestNotParsed()
                .ifPresent(repository::parseFile);
    }
}
