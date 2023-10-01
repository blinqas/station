locals {
  tags = merge(
    {
      "stationId"   = random_id.workload.hex,
      "environment" = var.environment_name,
    },
    var.tags
  )
}
