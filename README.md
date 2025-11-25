<div align="center">
  <h1>
    Data-to-Model Challenge Infrastructure Template
  </h1>

  <h3>
    Ready-to-use workflow template for evaluating prediction files submitted on
    <a href="https://www.synapse.org" title="Synapse.org">Synapse.org</a>
  </h3>

  <br/>

  <img 
    alt="GitHub release (latest by date)" 
    src="https://img.shields.io/github/release/sage-bionetworks-challenges/data-to-model-challenge-workflow?label=latest%20release&display_name=release&style=flat-square&color=blue">
  <img 
    alt="GitHub Release Date" 
    src="https://img.shields.io/github/release-date/sage-bionetworks-challenges/data-to-model-challenge-workflow?style=flat-square&color=green">
  <img 
    alt="GitHub" 
    src="https://img.shields.io/github/license/sage-bionetworks-challenges/data-to-model-challenge-workflow?style=flat-square&color=orange">
</div>


### 💡 Should You Use This Template?

The data-to-model (d2m) workflow is typically used when participants are
able to download the challenge data, train their model locally, and submit
their predictions file for evaluation against the hidden groundtruth data.

### 🚀 Quick Start

* **Customize evaluation logic:** modify the scoring and validation scripts
  within the `evaluation` folder
* **Configure workflow:** adapt `workflow.cwl` (and `writeup-workflow.cwl`,
  if applicable) to define the inputs and steps specific to your challenge
* **Test your changes:** use [`cwltool`](https://github.com/common-workflow-language/cwltool)
  to test your CWL scripts within the `steps`  folder

---

### Technical Details & Resources

#### Repository structure

This template provides all necessary components for a full challenge pipeline:

```
.
├── evaluation      // core scoring and validation scripts
├── README.md
├── steps           // individual CWL scripts (called by the main workflow CWL)
├── workflow.cwl          // CWL workflow for evaluating submissions
└── writeup-workflow.cwl  // CWL workflow to validate and archive writeup submissions
```

#### Resource docs 

This template is built using CWL and Docker, and is designed to be handled by the
SynapseWorkflowOrchestrator orchestration tool. For detailed information on utilizing
these core technologies, please refer to their docs below:

* CWL: https://www.commonwl.org/user_guide/
* Docker: https://docs.docker.com/get-started/
* SynapseWorkflowOrchestrator: https://github.com/Sage-Bionetworks/SynapseWorkflowOrchestrator
