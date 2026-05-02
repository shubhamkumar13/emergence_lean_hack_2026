# leanhack

## Pre-Build Instructions

1. install mise `curl https://mise.run | sh`
2. install all the packages needed by mise `mise install`
2. create the binary executable `mise exec bun -- bun build ./scraper/index.ts --compile --outfile ./scraper-exe`

## Build Instructions

1. `lake clean`
2. `lake update`
3. `lake cache get`
4. `lake build`

## Running instructions
1. `.lake/build/bin/leanhack`

# Emergence
## Origin

This project was built during the **LeanLang for Verified
Autonomy Hackathon** (April 17–18 + online through May 1,
2026) at the **Indian Institute of Science (IISc),
Bangalore**.
Sponsored by **[Emergence AI](https://www.emergence.ai)**
Organized by **[Emergence India Labs]
(https://east.emergence.ai)** in collaboration with
**IISc Bangalore**.

## Acknowledgments
This project was made possible by:
- **Emergence AI** — Hackathon sponsor
- **Emergence India Labs** — Event organizer and
research direction
- **Indian Institute of Science (IISc), Bangalore** —
Academic partner, hackathon co-design, tutorials,
and mentorship

## Links
- [Hackathon Page](https://east.emergence.ai/
hackathon-april2026.html)
- [Emergence India Labs](https://east.emergence.ai)
- [Emergence AI](https://www.emergence.ai)

