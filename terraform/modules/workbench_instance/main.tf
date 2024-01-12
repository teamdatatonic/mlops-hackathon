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
resource "google_workbench_instance" "instance" {
  disable_proxy_access = false
  location             = var.region
  name                 = var.name
  project              = var.project_id
  gce_setup {
    disable_public_ip    = false
    enable_ip_forwarding = false
    machine_type         = var.machine_type
    tags                 = [
        "deeplearning-vm",
        "notebook-instance",
    ]
    boot_disk {
        disk_size_gb = "150"
    }
    data_disks {
        disk_size_gb = "100"
    }
    network_interfaces {
        network = var.network_id
        subnet  = var.subnet_id
    }
    service_accounts {
      email = var.service_account_email
    }
  }
}
