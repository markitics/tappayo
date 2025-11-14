 "  The broken commit (71827a6) is preserved in git history if you ever want to reference it"
really?
I thought we over-wrote it by going back to 73e2bed

⏺ Good catch! Let me clarify:

  Yes, it's still there - for now. Let me show you:

⏺ Bash(git log --oneline --all | head -10)
  ⎿ 73e2bed Add custom keypad instead of system keypad. It's ugly and causes the input to be d
    uplicated, but it's a fine start. Add toggle whether it should auto-dismiss after adding a
     freely-typed (aka custom) item to cart. Add toggle in settings for whole dollar input vs
    … +20 lines (ctrl+o to expand)



⏺ Interesting! 71827a6 is NOT showing up. Let me check if it's still accessible:

⏺ Bash(git show 71827a6 --stat)
  ⎿  commit 71827a6d5fe039e1e4612d2ae9ecdcc239d58291
     Author: markitics <m@rkmoriarty.com>
     Date:   Fri Nov 14 01:27:38 2025 -0800
     … +9 lines (ctrl+o to expand)

⏺ Ah! It IS still there! You can access it by its hash 71827a6, it's just not pointed to by any
   branch anymore. Here's the situation:

  What happened:
  - The commit 71827a6 still exists in git's database
  - But the ui-tweaks branch no longer points to it (we moved the pointer back to 73e2bed)
  - It's what git calls "unreachable" (no branch or tag points to it)

  What will happen:
  - You can still access it RIGHT NOW using the hash: git show 71827a6
  - But eventually (after ~30-90 days), git's garbage collection will permanently delete it
  - If you want to keep it forever, you could tag it: git tag broken-modal-attempt 71827a6

  For now: It's accessible but orphaned. If you want to be extra safe and preserve those ideas,
   should I create a tag for it?

