class User < ApplicationRecord
	attr_accessor :remember_token, :activation_token
	before_save   :downcase_email
	before_create :create_activation_digest
	validates :name, presence: true, length: { maximum: 50 }
	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
	validates :email, presence: true, length: { maximum: 255 }, format: { with: VALID_EMAIL_REGEX }, uniqueness:  { case_sensitive: false }
	validates :password, presence: true, length: { minimum: 8, maximum: 255 }, allow_nil: true
	has_secure_password

	# 渡された文字列のハッシュ値を返す
	def User.digest(string)
		cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
														BCrypt::Engine.cost
		BCrypt::Password.create(string, cost: cost)
	end

	# ランダムなトークンを返す
	def User.new_token
		SecureRandom.urlsafe_base64
	end

	# トークンがダイジェストと一致したらtrueを返す
	def authenticated?(attribute, token)
		digest = send("#{attribute}_digest")
		return false if digest.nil?
		BCrypt::Password.new(digest).is_password?(token)
		return true
	end

	# アカウントを有効にする
	def activate
		update_attribute(:activated,    true)
		update_attribute(:activated_at, Time.zone.now)
	end

	# 有効化用のメールを送信する
	def send_activation_email
		UserMailer.account_activation(self).deliver_now
	end
	
	def activated?
		return false if !self.activated
		return true
	end

	private

    # メールアドレスをすべて小文字にする
    def downcase_email
      self.email = email.downcase
    end

	# 有効化トークンとダイジェストを作成および代入する
    def create_activation_digest
		self.activation_token  = User.new_token
		self.activation_digest = User.digest(activation_token)
	end
end
