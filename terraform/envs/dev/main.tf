/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


terraform {
  required_version = ">= 0.13"
  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "~> 5.11.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.56.0"
    }

  }

  # Terraform state stored in GCS
  backend "gcs" {}
}

# Core Vertex Pipelines infrastructure
module "vertex_deployment" {
  source     = "../../modules/vertex_deployment"
  project_id = var.project_id
  region     = var.region
}

# Cloud Scheduler jobs (for triggering pipelines)
module "scheduler" {
  for_each            = var.cloud_schedulers_config
  source              = "../../modules/scheduled_pipelines"
  project_id          = var.project_id
  region              = var.region
  name                = each.key
  description         = lookup(each.value, "description", null)
  schedule            = each.value.schedule
  time_zone           = lookup(each.value, "time_zone", "UTC")
  topic_name          = module.vertex_deployment.pubsub_topic_id
  template_path       = each.value.template_path
  enable_caching      = lookup(each.value, "enable_caching", null)
  pipeline_parameters = lookup(each.value, "pipeline_parameters", null)
  depends_on          = [module.vertex_deployment]
}

resource "google_compute_network" "network" {
  name = "default-vpc"
  auto_create_subnetworks = true
}

resource "google_compute_subnetwork" "subnetwork" {
  name = "default-vpc"
  network = google_compute_network.network.id
  region = var.region
  ip_cidr_range = "10.154.0.0/20"
}

data "google_compute_default_service_account" "default" {
  project = var.project_id
}

module "instances" {
  for_each   = merge(var.presenters, var.attendees)
  source     = "../../modules/workbench_instance"
  project_id = var.project_id
  region     = "${var.region}-a"
  name       = each.key
  network_id = google_compute_network.network.id
  subnet_id  = google_compute_subnetwork.subnetwork.id
  service_account_email = data.google_compute_default_service_account.default.email
}

resource "google_project_iam_member" "project" {
  for_each = var.attendees
  project  = var.project_id
  role     = "roles/editor"
  member   = "user:${each.value}"
}
