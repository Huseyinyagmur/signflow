import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "loading"]

  submit() {
    this.buttonTarget.disabled = true
    this.loadingTarget.hidden = false
  }
}
