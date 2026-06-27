# Model Selection

Choose tools by job, not hype. This note is current as of 2026-06-24 and should be refreshed when model lineups or product names change.

Use stronger reasoning models for:

- Ambiguous planning
- Code architecture
- Debugging hard issues
- Math or logic
- Long context synthesis
- Risky decisions

Use faster models for:

- Summaries
- Rewrites
- Brainstorming
- Classification
- Simple extraction
- Drafting routine messages

Use specialized tools for:

- Search when facts may be current
- Code execution when answers need computation
- Image models for visual assets
- Transcription for audio/video notes

Decision rules:

- If the task is ambiguous, start with a stronger reasoning model.
- If the task is repetitive and low risk, use a faster cheaper model.
- If facts may have changed, use web search or source documents.
- If correctness matters, ask for uncertainty and verify against sources.
- If output needs to be machine-readable, request structured output.
- If the model needs private context, minimize what you provide and remove secrets.

Source-backed anchors:

- OpenAI docs separate models, reasoning, tools, structured outputs, web search, file search, images, audio, and safety guidance.
- Anthropic and Google prompt guidance both emphasize clear instructions, context, examples, and iteration.
- NIST's AI Risk Management Framework frames AI use around trustworthiness, risk, measurement, and governance.

Related source notes: [[Source - OpenAI Prompt Engineering]], [[Source - Anthropic Prompt Engineering]], [[Source - Google Prompting Strategies]], [[Source - NIST AI RMF]]

Related: [[AI Evaluation Checklist]], [[Personal AI Stack]]
