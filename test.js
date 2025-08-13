{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-address-pools": [
    {"base":"10.0.0.0/8","size":24}
  ]
{
  "max-concurrent-uploads": 1,
  "max-http-attempts": 10,
  "default-timeout": "30m"
}
}