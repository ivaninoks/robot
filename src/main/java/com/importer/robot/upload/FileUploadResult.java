package com.importer.robot.upload;

import lombok.*;

@Getter
@RequiredArgsConstructor
public class FileUploadResult {

    private final Status status;

    static FileUploadResult successful() {
        return new FileUploadResult(Status.SUCCESSFUL);
    }

    static FileUploadResult failed() {
        return new FileUploadResult(Status.FAILED);
    }

    enum Status {
        SUCCESSFUL,
        FAILED
    }
}
