resource "aws_kinesis_stream" "stream" {
  for_each         = { for k, v in var.service_apps : k => v }
  name             = "${var.service_apps[each.key].stream_name}"
  shard_count      = "${var.service_apps[each.key].shard_count}"
  retention_period = "${var.service_apps[each.key].retention_period}"

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
    "OutgoingRecords",
    "ReadProvisionedThroughputExceeded",
    "WriteProvisionedThroughputExceeded",
    "IncomingRecords",
    "IteratorAgeMilliseconds",
  ]


}
