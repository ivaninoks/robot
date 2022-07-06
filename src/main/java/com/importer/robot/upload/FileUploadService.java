package com.importer.robot.upload;

import com.importer.robot.model.*;
import lombok.*;
import lombok.extern.slf4j.*;
import org.springframework.stereotype.*;
import org.springframework.web.multipart.*;

import java.io.*;
import java.nio.file.*;
import java.util.stream.*;

import static com.importer.robot.upload.FileUploadResult.*;
import static java.nio.file.Files.*;
import static java.nio.file.StandardCopyOption.*;
import static java.util.Optional.*;

@Slf4j
@Component
@RequiredArgsConstructor
public class FileUploadService {

    private final FileRepository repository;

    public FileUploadResult upload(MultipartFile multipartFile) {
        File tempFile = null;

        try (InputStream inputStream = multipartFile.getInputStream()) {
            tempFile = createTempFile(null, null).toFile();
            copy(inputStream, tempFile.toPath(), REPLACE_EXISTING);
            repository.save(new FileEntity(Files.lines(tempFile.toPath())
                    .collect(Collectors.joining())));
        } catch (IOException ioe) {
            throw new FileUploadException("Failed uploading file due to:", ioe);
        } finally {
            ofNullable(tempFile).ifPresent(File::delete);
        }
        return successful();
    }
}
