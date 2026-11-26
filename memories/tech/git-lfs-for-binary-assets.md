# Put binary assets in Git LFS, keep Godot text files in git, never commit .godot/ or builds

- Area: tech
- Date / source: 2026-11-26, https://docs.github.com/en/billing/concepts/product-billing/git-lfs
- Confidence: medium
- Apply when: creating a project repo layout or CI checkout.

GitHub Free/Pro: 10 GiB LFS storage + 10 GiB bandwidth free, then $0.07/GiB-month storage and
$0.0875/GiB bandwidth (metered; data packs retired). CI clones count as bandwidth, so cache LFS
in Actions. Track `*.png *.wav *.ogg *.psd *.aseprite *.ttf *.glb`; `.tscn/.tres/.gd` stay plain git;
`.godot/` is a regenerable import cache. git-lfs is preinstalled in the container.
