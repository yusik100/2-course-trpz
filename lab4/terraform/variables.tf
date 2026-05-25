variable "vm_memory" {
  description = "Обсяг оперативної пам'яті для ВМ"
  default     = "1024 mib"
}

variable "vm_cpus" {
  description = "Кількість ядер процесора"
  default     = 1
}