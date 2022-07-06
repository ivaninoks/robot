package com.importer.robot.model;


import lombok.*;
import lombok.Getter;
import lombok.Setter;

import javax.persistence.*;

import static javax.persistence.GenerationType.*;

@Entity
@Getter
@Setter
@NoArgsConstructor
@Table(name = "raw_file")
@SequenceGenerator(name = "raw_file_seq_gen", sequenceName = "raw_file_seq", allocationSize = 1)
public class FileEntity {

    @Id
    @GeneratedValue(generator = "raw_file_seq_gen", strategy = SEQUENCE)
    private Long id;

    private String data;

    private Boolean parsed = false;

    public FileEntity(String data) {
        this.data = data;
    }
}
