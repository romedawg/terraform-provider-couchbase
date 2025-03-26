############
# Provider #
############

terraform {
  required_version = ">= 1.10.5"
  required_providers {
    couchbase = {
      version = "~> 1.1.3"
      source  = "budisky.com/couchbase/couchbase"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.1"
    }
  }
}

provider "couchbase" {
  address            = "couchbase"
  client_port        = 8091
  node_port          = 11210
  username           = "Administrator"
  password           = "123456"
  management_timeout = 10
}

###########
# Buckets #
###########
resource "couchbase_bucket_manager" "bucket_1" {
  name                     = "bucket_1"
  ram_quota_mb             = 512
  flush_enabled            = false
  max_expire               = 0
  conflict_resolution_type = "seqno"
  compression_mode         = "passive"
  num_replicas             = 0
}

################
# Bucket scope #
################
resource "couchbase_bucket_scope" "scope_1" {
  name   = "scope_1"
  bucket = couchbase_bucket_manager.bucket_1.name
}

######################
# Bucket collection #
######################
resource "couchbase_bucket_collection" "collection_1" {
  name       = "collection_1"
  scope      = couchbase_bucket_scope.scope_1.name
  bucket     = couchbase_bucket_manager.bucket_1.name
  max_expire = 20
}

###############
# User groups #
###############
resource "couchbase_security_group" "user_group_1" {
  name        = "user_group_1"
  description = "user group"

  role {
    name   = "query_update"
    bucket = "*"
  }

  role {
    name       = "query_select"
    bucket     = "*"
    scope      = ""
    collection = ""
  }
}

#########
# Users #
#########
resource "random_password" "user_password" {
  length  = 10
  special = false
  lower   = true
  upper   = true
}

resource "couchbase_security_user" "user_1" {
  username = "user_1"
  password = random_password.user_password.result

  groups = [couchbase_security_group.user_group_1.id]
}

###########
# Indexes #
###########
resource "couchbase_primary_query_index" "primary_index_1" {
  name   = "primary_index_1"
  bucket = couchbase_bucket_manager.bucket_1.name
}

resource "couchbase_query_index" "index_1" {
  name        = "index_1"
  bucket      = couchbase_bucket_manager.bucket_1.name
  fields      = ["`action`"]
  num_replica = 0
  condition   = "(`type` = \"http://example.com\")"
}
