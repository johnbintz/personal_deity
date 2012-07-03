job_type :god, '<%= generate_personal_diety_command %>'

every(:reboot) { god "run" }

