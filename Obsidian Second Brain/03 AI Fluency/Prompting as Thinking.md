# Prompting as Thinking

Good prompting is clear thinking made visible.

Prompt ingredients:

- Role: who the AI should act as
- Goal: what outcome you want
- Context: what it needs to know
- Constraints: what matters
- Examples: what good looks like
- Process: how to think or what steps to follow
- Output: format, tone, length

Useful prompt patterns:

- Critic: "Find weaknesses in this plan."
- Tutor: "Teach me through questions."
- Operator: "Turn this into a checklist."
- Strategist: "Give me three options and tradeoffs."
- Editor: "Make this clearer without changing meaning."
- Simulator: "Roleplay the likely objections."

Related: [[AI Copilot Protocol]], [[Context Engineering]], [[AI Evaluation Checklist]]

## Prompt Debugging

When a response is bad, do not immediately blame the model. Diagnose the prompt.

- Missing goal: the model does not know what success looks like.
- Missing context: the model is guessing from general knowledge.
- Missing constraints: the model gives something plausible but unusable.
- Missing examples: style, format, or depth is off.
- Missing evaluation: there is no standard for checking quality.
- Too many jobs: the prompt asks for strategy, drafting, editing, and verification all at once.

Repair prompt:

```text
This output missed the mark. Diagnose whether the issue is goal, context, constraints, examples, process, or output format. Then rewrite my prompt so a model is more likely to produce the desired result.
```

## Personal Prompt Style

Default style to use:

- Be specific about the job.
- Provide the source material.
- Ask for a first pass before polishing.
- Ask for alternatives when deciding.
- Ask for critique when quality matters.
- Ask for citations or exact source references when facts matter.
