locals {
  tags = merge(
    {
      "stationId" = random_id.workload.hex,
    },
    var.tags
  )
}
