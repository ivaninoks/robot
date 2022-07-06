package com.importer.robot.model;

import com.importer.robot.model.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.jpa.repository.query.*;
import org.springframework.data.repository.query.*;

import java.util.*;

public interface FileRepository extends JpaRepository<FileEntity, Long> {
    @Procedure(procedureName = "PARSE_XML")
    String parseFile(@Param("rawFileId") Long rawFileId);

    @Query(value = "SELECT id FROM raw_file WHERE NOT parsed ORDER BY id DESC LIMIT 1", nativeQuery = true)
    Optional<Long> latestNotParsed();

    @Query(value = "SELECT id FROM raw_file WHERE NOT parsed AND (EXTRACT(EPOCH FROM (created - NOW())) / 60) >= 10", nativeQuery = true)
    List<Long> notParsedWithinTenMinutes();
}
