# frozen_string_literal: true

class ChatRoom < ApplicationRecord
  validates :name, presence: true

  belongs_to :user
  has_many :chat_room_participants, dependent: :destroy
  has_many :chat_room_messages, dependent: :destroy

  scope :find_by_name, ->(phone_number) { find_by(name: phone_number) }
end
