# delta-detection

## table of contents

- [getting started](#getting-started)
- [project layout](#project-layout)
- [algorithms](#algorithms)
- [assumptions](#assumptions)
- [generality](#generality)
- [next steps](#next-steps)
- [AI usage advisory](#ai-usage-advisory)

This README intentionally stays lightweight and mainly serves as an index to the documents under `docs/`, where the design decisions and implementation details are explained in more depth.

## getting started

- [`docs/getting-started.md`](docs/getting-started.md)

  Describes how to set up and run the project.

## project layout

- [`docs/layout.md`](docs/layout.md)

  Describes the overall structure of the repository and the purpose of each directory.

## algorithms

- [`docs/algo.load.md`](docs/algo.load.md)

  Describes how data is loaded into the raw layer.

- [`docs/algo.processing.md`](docs/algo.processing.md)

  Describes the SCD Type 2-like processing used to maintain the entity layer.

- [`docs/algo.syncvalidation.md`](docs/algo.syncvalidation.md)

  Describes the transformation and validation steps used to generate the output files.

## assumptions

- [`docs/assumptions.md`](docs/assumptions.md)

  Lists the assumptions made during implementation and areas where the specification leaves room for interpretation.

## generality

- [`docs/generality.md`](docs/generality.md)

  Discusses how the current approach could be extended and generalized.

## next steps

- [`docs/nextsteps.md`](docs/nextsteps.md)

  Documents possible improvements and future work.

## AI usage advisory

- [`docs/ai-usage-advisory.md`](docs/ai-usage-advisory.md)

  Declares how AI-assisted tools were used during the implementation.