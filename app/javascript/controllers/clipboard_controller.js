import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "status"]

  async copy() {
    try {
      await navigator.clipboard.writeText(this.inputTarget.value)
      this.statusTarget.textContent = "Bağlantı kopyalandı. Alıcınıza iletebilirsiniz."
    } catch {
      this.inputTarget.focus()
      this.inputTarget.select()
      this.statusTarget.textContent = "Otomatik kopyalanamadı. Seçili bağlantıyı Ctrl+C ile kopyalayın."
    }
  }
}
