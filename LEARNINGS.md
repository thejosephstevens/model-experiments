# Learnings
This was my first time working on a model training project and there were a number of things I rapidly learned.

## 1. Learn from prior art
Training models is not a novel practice. There are existing projects like MLFlow, DVC, BentoML, whylogs, and Kubeflow that address various parts of this problem space. After some initial ideation on what the project should look like, I did a bit of research on existing tools and then had much better context for what I was building. Notably, the `experiment` concept is one I hadn't worked with before, but it became incredibly obvious how that would be useful as a building block for iterative model development.

In particular, looking at Kubeflow related the process of model training management to infrastructure ecosystem components that I'm extremely fluent in, allowing me to more quickly understand what I was looking at in familiar terms.

## 2. Model training is expensive
Training models is expensive. It's slow on CPUs, the assets can be very large, and it's difficult to know what your outcomes are going to be before you complete training. This means if you're performing experimental exploration, it's valuable to cache assets (e.g. models, datasets and even training outputs), so that you're minimizing time spent on duplicative work.

## 3. Model training cares about your hardware
When you're writing in traditional programming languages, you'll run into some problems with operating systems and environments, but for the most part, popular modern languages are pretty darn good at portability and consistent results without the developer having to think very much.

Model training is more sensitive than this. There's the obvious differences of CPU vs GPU, more memory, etc., but also details like availability of floating point operations and other details may be completely unavailable depending on your underlying hardware, meaning that training on an Apple Silicon Macbook is very different than training on a GPU-equipped server. This limits what training configs you can even run, based on your current platform.

## 4. Model training configuration can be done intuitively, but you still need to run a lot of experiments
There are specialized skills you can develop in learning what parameters make sense to tune given certain patterns that you're seeing in your eval results. That said, as you scale out to handle larger datasets and more complex models, it will be difficult to consistently project behaviors, even with lots of experience. As a result, it's important to be able to establish a measurable evaluation methodology in order to automate and parallelize the experimentation process over many hyperparameter configurations, datasets, models, etc. This means in order to drive success you need to pair ML intuition with well structured, easy-to-operate, scalable experimentation infrastructure.

## 5. Extension Opportunities
In my work and reasearch, a number of different possibilities became clear for extending this project.

### 1. Dataset Transformation Pipeline
Not all text datasets are in a format ready for training and may require transformation before usage. For text this would generally be getting `text` to `label` mappings, and may include supporting functionality like feature engineering, schema mapping, and multi-field concatenation.

### 3. Hyperparameter Tuning, Multi-Dataset & Multi-Model Experiments
As mentioned above, MLOps tooling needs to empower exploring many experiment combinations in an automated way. In order to more easily explore problem spaces in an automated way, it would be valuable to add support for hyperparameter tuning. This could be as simple as a grid search, or as complex as a Bayesian optimization. This could be coupled with the ability to run experiments on multiple datasets and models in a single run, allowing for matrix experiments to be run in a single command.

### 4. Dataset Quality & Analysis Tools
Datasets are not inherently good or bad. Similarly to evals on models, it's useful to have many ways of measuring the characteristics of a dataset to better understand its quality, how it can be changed when consuming it to improve outcomes, etc.

### 5. Model Versioning & Registry
In order to more easily track and manage your models, it would be valuable to add support for model versioning and registry. This could include things like tracking all trained models with metadata, version tagging, rollback capabilities, and model lineage. This makes it much easier for humans to understand the history of a model and make decisions about what to use, what to iterate on, what model to roll back to in a degraded state, etc.

### 5. Experiment Queueing & Scheduling
As you scale out experiment operations you encounter a resource management problem. It's valuable to be able to rapidly process many experiments at once, but that's also a great way to burn a budget. There need to be effective controls for fairly queueing experiments across multiple requestors, but also managing resource consumption so that you can get consistent RoI from your ML investments.

