import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "token", "status"]

  connect() {
    const fragment = new URLSearchParams(window.location.hash.slice(1))
    const token = fragment.get("token")
    if (!token) return
    // Fragments never reach HTTP access logs. Remove it before the next navigation.
    window.history.replaceState(null, "", window.location.pathname)
    this.tokenTarget.value = token
    this.statusTarget.textContent = "Sözleşmeniz açılıyor."
    this.formTarget.requestSubmit()
  }
}
