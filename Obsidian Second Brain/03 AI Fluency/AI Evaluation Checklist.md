# AI Evaluation Checklist

Before trusting an AI output, check:

- Does it answer the actual question?
- Did it use the context I gave?
- Are there unsupported claims?
- Is the reasoning visible enough to inspect?
- Are important edge cases covered?
- Are dates, names, prices, laws, and specs current?
- Could a simpler answer be better?
- What would I verify independently?

Red flags:

- Overconfident specifics without sources
- Smooth wording hiding vague logic
- Code that was not tested
- Advice that ignores constraints
- Missing privacy or security considerations

Related: [[Model Selection]], [[AI Research Workflow]]

## Trust Ladder

Use different standards for different stakes.

Low stakes:

- Brainstorming, naming, rough planning, rewriting
- Review for usefulness and move on

Medium stakes:

- Coding, public writing, learning notes, personal decisions
- Check logic, run tests, compare with sources, review edge cases

High stakes:

- Legal, medical, financial, security, privacy, career-impacting decisions
- Treat AI as a drafting or question-generation aid only
- Verify with authoritative sources or qualified people

## Hallucination Triggers

Be extra skeptical when asking for:

- Recent facts
- Specific prices, laws, policies, specs, or schedules
- Quotes
- Academic references
- Package versions
- Security advice
- Anything involving a person's current role or status

Related: [[AI Privacy and Safety]], [[AI Research Workflow]], [[Source Library]]
