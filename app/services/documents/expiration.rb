module Documents
  class Expiration
    def self.call(scope: Document.all)
      scope.where(status: "pending").where("expires_at <= ?", Time.current).find_each do |document|
        begin
          document.expire!
        rescue Document::InvalidTransition
          # A concurrent signature or expiration may have won the row lock.
          raise if document.reload.pending? && document.expires_at <= Time.current
        end
      end
    end
  end
end
