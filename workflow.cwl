#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: Workflow
label: Evaluation workflow for file submissions
doc: >
  This workflow validates and scores the submitted predictions file

requirements:
  - class: StepInputExpressionRequirement

inputs:
  # ------------------------------------------------------------------------------
  # SynapseWorkflowOrchestrator inputs - do not remove or modify.
  # ------------------------------------------------------------------------------
  adminUploadSynId:
    label: synID to folder on Synapse that is downloadable by admin only
    type: string
  submissionId:
    label: Submission ID
    type: int
  submitterUploadSynId:
    label: synID to folder on Synapse that is downloadable by submitter and admin
    type: string
  synapseConfig:
    label: Abstolute filepath to .synapseConfig file
    type: File
  workflowSynapseId:
    label: synID to workflow file
    type: string

  # ------------------------------------------------------------------------------
  # Core challenge configuration - MUST be updated and specific to your challenge.
  # ------------------------------------------------------------------------------
  organizersId:
    label: userID or teamID for the organizers team on Synapse
    type: string
    default: "3379097" # Placeholder - MUST be updated
  groundtruthSynId:
    label: synID for the groundtruth file on Synapse
    type: string
    default: "syn123"  # Placeholder - MUST be updated

  # ------------------------------------------------------------------------------
  # Optional challenge configuration - update as needed.
  # ------------------------------------------------------------------------------
  errors_only:
    label: Send email notifications only for errors (no notification for valid submissions)
    type: boolean
    default: true
  private_annotations:
    label: Annotations to be withheld from participants
    type: string[]
    default: ["submission_errors"]

outputs: []

steps:

  01_set_submitter_folder_permissions:
    doc: >
      Give challenge organizers `download` access to the docker logs
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/set_permissions.cwl
    in:
      - id: entityid
        source: "#submitterUploadSynId"
      - id: principalid
        source: "#organizersId"
      - id: permissions
        valueFrom: "download"
      - id: synapse_config
        source: "#synapseConfig"
    out: []

  01_download_submission:
    doc: Download submitted file
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/get_submission.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: synapse_config
        source: "#synapseConfig"
    out:
      - id: filepath
      - id: docker_repository
      - id: docker_digest
      - id: entity_id
      - id: entity_type
      - id: evaluation_id
      - id: results
      
  01_download_groundtruth:
    doc: Download groundtruth file
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks-Workflows/cwl-tool-synapseclient/v1.4/cwl/synapse-get-tool.cwl
    in:
      - id: synapseid
        source: "#groundtruthSynId"
      - id: synapse_config
        source: "#synapseConfig"
    out:
      - id: filepath

  02_validate:
    doc: Validate format of submitted file, prior to scoring
    run: steps/validate.cwl
    in:
      - id: pred_file
        source: "#01_download_submission/filepath"
      - id: entity_type
        source: "#01_download_submission/entity_type"
    out:
      - id: results
      - id: status
      - id: invalid_reasons

  03_send_validation_results:
    doc: Send email of the validation results to the submitter
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/validate_email.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: synapse_config
        source: "#synapseConfig"
      - id: status
        source: "#02_validate/status"
      - id: invalid_reasons
        source: "#02_validate/invalid_reasons"
      - id: errors_only
        source: "#errors_only"
    out: [finished]

  03_add_validation_annots:
    doc: Update the submission annotations with validation results
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/annotate_submission.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: annotation_values
        source: "#02_validate/results"
      - id: to_public
        default: true
      - id: force
        default: true
      - id: synapse_config
        source: "#synapseConfig"
    out: [finished]

  04_check_validation_status:
    doc: >
      Check the validation status of the submission; if 'INVALID', throw an
      exception to stop the workflow at this step. That way, the workflow
      will not attempt scoring invalid predictions file.
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/check_status.cwl
    in:
      - id: status
        source: "#02_validate/status"
      - id: previous_annotation_finished
        source: "#03_add_validation_annots/finished"
      - id: previous_email_finished
        source: "#03_send_validation_results/finished"
    out: [finished]

  05_score:
    run: steps/score.cwl
    in:
      - id: pred_file
        source: "#01_download_submission/filepath"
      - id: groundtruth_file
        source: "#01_download_groundtruth/filepath"
      - id: check_validation_finished
        source: "#04_check_validation_status/finished"
    out:
      - id: results
      - id: status
      
  06_send_score_results:
    doc: >
      Send email of the evaluation status (optionally with scores) to the submitter
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/score_email.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: synapse_config
        source: "#synapseConfig"
      - id: results
        source: "#05_score/results"
      - id: private_annotations
        source: "#private_annotations"
    out: []

  06_add_score_annots:
    doc: >
      Update `submission_status` and add the scoring metric annotations
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/annotate_submission.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: annotation_values
        source: "#05_score/results"
      - id: to_public
        default: true
      - id: force
        default: true
      - id: synapse_config
        source: "#synapseConfig"
      - id: previous_annotation_finished
        source: "#03_add_validation_annots/finished"
    out: [finished]

  07_check_score_status:
    doc: >
      Check the scoring status of the submission; if 'INVALID', throw an
      exception so that final status is 'INVALID' instead of 'ACCEPTED'
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/check_status.cwl
    in:
      - id: status
        source: "#05_score/status"
      - id: previous_annotation_finished
        source: "#06_add_score_annots/finished"
    out: [finished]
