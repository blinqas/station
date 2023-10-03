locals {
  tags = merge(
    {
      "station-id"  = random_id.workload.hex,
      "environment" = var.environment_name,
    },
    var.tags
  )
}
