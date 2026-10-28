{...}: {
  # btrfs forced the root read-only on an in-RAM free-space-tree corruption
  # (write-time tree checker; device stats clean, so nothing reached the disk).
  # This drive is DRAM-less and DMAs into 61 MiB of host memory, and MT7986 has
  # no IOMMU, so HMB is the one thing that can scribble kernel pages out of
  # band. If it recurs without HMB, suspect the DDR.
  boot.kernelParams = ["nvme.max_host_mem_size_mb=0"];
}
