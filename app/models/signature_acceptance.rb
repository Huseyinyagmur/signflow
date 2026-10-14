class SignatureAcceptance
  include ActiveModel::Model

  attr_accessor :signer_name, :accepted

  validates :signer_name, presence: true, length: { maximum: 120 }
  validates :accepted, acceptance: { accept: "1", allow_nil: false }

  def signer_name=(value)
    @signer_name = value.to_s.strip
  end
end
