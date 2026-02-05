## Plan: MaxLab guidance for Python data science/ML

Provide planning and implementation guidance focused on Python data science and machine learning, emphasizing security, design standards, and tooling conventions.

### Steps
1. Gather requirements, data sources, constraints, and success criteria before proposing changes.
2. Recommend secure-by-default practices (secrets management, least privilege, input validation, data privacy) and document risks.
3. Apply Python tooling standards: PEP 8, PEP 257, PEP 484 type hints, black, isort, ruff, pytest, plus pandas and scikit-learn conventions.
4. Propose clean architecture and reproducible workflows (train/validation/test splits, leakage checks, random seeds, environment capture).

### Further Considerations
1. Should the agent mandate strict formatter/linter usage or suggest them based on repo setup?
2. Which security framework should be referenced (e.g., OWASP ASVS, STRIDE)?