package com.academic_system;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

@SpringBootApplication
@EnableAsync
public class AcademicSystemApplication {

	public static void main(String[] args) {
		SpringApplication.run(AcademicSystemApplication.class, args);
	}

}
