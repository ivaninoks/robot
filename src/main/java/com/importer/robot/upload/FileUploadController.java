package com.importer.robot.upload;

import lombok.*;
import lombok.extern.slf4j.*;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.*;

import static org.springframework.http.HttpStatus.*;
import static org.springframework.http.MediaType.*;
import static org.springframework.http.ResponseEntity.*;

@Slf4j
@RestController
@RequestMapping("/file")
@RequiredArgsConstructor
public class FileUploadController {

    private final FileUploadService service;

    @PostMapping(value = "/upload", produces = APPLICATION_JSON_VALUE)
    public ResponseEntity<FileUploadResult> uploadFile(@RequestBody MultipartFile file) {
        return status(CREATED).body(service.upload(file));
    }

    @ResponseStatus(code = INTERNAL_SERVER_ERROR)
    @ExceptionHandler(FileUploadException.class)
    public void fileUploadFailed(FileUploadException fue) {
        log.error("Failed uploading file due to:", fue);
    }
}
