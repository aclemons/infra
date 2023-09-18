resource "hcloud_server" "prosody" {
  name        = "prosody"
  server_type = "cpx21"
  image       = "ubuntu-22.04"
}

resource "hcloud_ssh_key" "id_ed25519" {
  name       = "id_ed25519 public key"
  public_key = file("~/.ssh/id_ed25519.pub")
}
