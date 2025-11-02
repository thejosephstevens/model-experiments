# Overview
At Arcade, we’re building the infrastructure that lets AI take real actions in the real world — not just chat. This exercise simulates a slice of the work you’d do here: building, deploying, and monitoring a model that powers a real product.
 

First, pick a use-case that is interesting to you. Select any model you like and fine tune it on a public dataset that will transform the model into something tailor-made for your use case. Then, prove fine-tuning made your new model better. Finally, host the model so you can demonstrate it working.
 

To get inspired, check out all these fine-tuned versions of Quen3B for niche (and not-so-niche) use cases:
https://huggingface.co/models?other=base_model:finetune:Qwen/Qwen3-4B-Instruct-2507
 

The task is scoped to take 5–8 hours total. You’re encouraged to use pre-trained models and hosted tools where it makes sense.

# The Challenge
Your task: Fine tune a model to succeed at a specific use case, and prove that it works. Include a way to test or demonstrate that your model, ideally by hosting it.

## Requirements
### Model & Data
Use a small open dataset or synthetic examples. Check this into your deliverable repo.
- Show how you evaluated your model’s performance.
- Include the code and tools you used for fine tuning, and reproduction steps.
 

### Ops & Monitoring
- Include basic logging or metrics (e.g., latency histogram, request count).
- Include a script or method for automated evaluation.
 

### Quality
- Clean, modular, and well-documented code.
- Use type hints and include full unit test coverage.
- Add a short README explaining what you did so that another engineer can follow your steps and reproduce your work.

### Deliverables
- GitHub Repository: Host your toolkit in a public GitHub repository on your own account.
- Model Hosting: Host the model in a sharable place, like HuggingFace
- Email Submission: Send an email with the repository and model links to evan@arcade.dev for review.

### Structure
- `typer script` for the main entry point
- Must be reusable with different models and datasets.

## Evaluation Criteria
Your project will be evaluated based on:
- Functionality: The model works and delivers meaningful features.
- Testing: You can prove that your fine-tuning process improved performance over the base model for your use-case.
- Documentation: Clear instructions and documentation are provided.
- Originality: Your use-case is unique and interesting!
 

## Tips for Success
- Focus on Core Features: Due to the time limit, implement the features with the highest impact first.
- Ensure Reproducibility: Anyone should be able to clone your repo and run the toolkit without issues.
- Document Your Work: Clear, concise documentation will help others understand your toolkit’s usage and benefits. Provide images or videos if that helps.