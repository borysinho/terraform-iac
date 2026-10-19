mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "222234418877" }
  }
}

run "protect_shared_state" {
  command = plan

  assert {
    condition = (
      aws_s3_bucket.state.force_destroy == false &&
      aws_s3_bucket_versioning.state.versioning_configuration[0].status == "Enabled" &&
      one(aws_s3_bucket_server_side_encryption_configuration.state.rule).apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    )
    error_message = "El estado compartido requiere versionado, cifrado y protección frente al borrado del bucket con objetos."
  }

  assert {
    condition = (
      aws_s3_bucket_public_access_block.state.block_public_acls &&
      aws_s3_bucket_public_access_block.state.block_public_policy &&
      aws_s3_bucket_public_access_block.state.ignore_public_acls &&
      aws_s3_bucket_public_access_block.state.restrict_public_buckets &&
      aws_s3_bucket_ownership_controls.state.rule[0].object_ownership == "BucketOwnerEnforced"
    )
    error_message = "El bucket de estado debe permanecer privado y sin ACL."
  }
}
