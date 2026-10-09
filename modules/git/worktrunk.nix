{ ... }:
{
  programs.worktrunk = {
    enable = true;
    settings.worktree-path = "~/worktrees/{{ owner }}/{{ repo }}/{{ branch | sanitize }}";
  };
}
