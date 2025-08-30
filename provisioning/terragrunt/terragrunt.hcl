terraform {
    source = "."

    extra_arguments "parallelism" {
      commands  = ["apply"]
      arguments = ["-parallelism=${get_env("TF_VAR_parallelism", "10")}"]
    }
}


remote_state {
  backend = "http"
  config = {
    address        = "https://git-service.ait.ac.at/api/v4/projects/2197/terraform/state/${get_aws_account_id()}_${replace(run_cmd("git", "rev-parse", "--abbrev-ref", "HEAD"), "/[/\\.]/", "_")}_${replace(basename(get_repo_root()), ".", "_")}"
    lock_address   = "https://git-service.ait.ac.at/api/v4/projects/2197/terraform/state/${get_aws_account_id()}_${replace(run_cmd("git", "rev-parse", "--abbrev-ref", "HEAD"), "/[/\\.]/", "_")}_${replace(basename(get_repo_root()), ".", "_")}/lock"
    unlock_address = "https://git-service.ait.ac.at/api/v4/projects/2197/terraform/state/${get_aws_account_id()}_${replace(run_cmd("git", "rev-parse", "--abbrev-ref", "HEAD"), "/[/\\.]/", "_")}_${replace(basename(get_repo_root()), ".", "_")}/lock"
    username       = "${get_env("GITLAB_USERNAME")}"
    password       = "${get_env("CR_GITLAB_ACCESS_TOKEN")}"
    lock_method    = "POST"
    unlock_method  = "DELETE"
    retry_wait_min = "5"
  }
}