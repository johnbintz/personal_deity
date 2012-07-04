job_type :god, '<%= generate_personal_deity_command %>'

every(:reboot) { god "run" }

