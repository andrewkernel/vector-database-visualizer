# AI Mental Models

Mental models make AI less magical and more usable.

## Prediction Engine, Not Oracle

Language models generate likely continuations from context. They can be useful without being authoritative. Treat confident wording as style, not proof.

Use this when:

- You are tempted to trust a fluent answer.
- The model gives a precise fact without a source.
- You need to separate usefulness from truth.

Related: [[AI Evaluation Checklist]]

## Context Window as Working Memory

The model can only use what is in the conversation or connected tools. Better context usually beats clever phrasing.

Practical move:

- Paste the relevant note, code, error, goal, constraints, and examples.
- Ask the model to restate the task before solving.

Related: [[Context Engineering]]

## AI as Exoskeleton

AI is best when it extends a human capability you are actively using: thinking, coding, writing, planning, researching, editing.

Bad pattern:

- "Do this for me while I disengage."

Good pattern:

- "Help me think through this, draft it, critique it, and improve it."

Related: [[AI Copilot Protocol]]

## The Human Holds Taste

AI can generate options. You decide what matters. Taste comes from domain knowledge, values, audience, and constraints.

Practice:

- Ask for ten options.
- Choose two.
- Explain why.
- Ask AI to infer your taste profile.

Related: [[Creative Output]], [[Prompting as Thinking]]

## Verification Is a Workflow

Verification is not a vibe. It is a repeatable process: identify claims, find sources, compare, test, and record uncertainty.

Related: [[AI Research Workflow]], [[AI Evaluation Checklist]], [[Source Library]]

