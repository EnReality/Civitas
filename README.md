# CIVITAS RP Framework
## License
CIVITAS is free to download and use for roleplay servers.

Redistribution, resale, or rebranding is not permitted without written
permission from Gritty Games.

- **Author:** Gritty Games

CIVITAS is a modular FiveM roleplay framework focused on society-first roleplay design. It provides lightweight core systems, organization and access primitives, and assets management so communities can build roleplay experiences without enforcing job/economy patterns.

Core philosophy
- Prioritize social systems, relationships, and emergent roleplay.
- Avoid automated grind, job gates, or economy-first mechanics.

What CIVITAS does NOT include
- No job systems or predefined role/job loops.
- No paychecks, XP, skill trees, or automated grind mechanics.
- No automated crime/economy systems or server-side gameplay loops.

Modular resource design
- Each `civitas-*` folder is a standalone FiveM resource.
- Resources communicate via exports and events only; there are no circular dependencies.
- The framework is an engine: implementers build server logic and game content on top of these resources.

This repository is a skeleton for incremental development.
