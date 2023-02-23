# frozen_string_literal: true

module Api
  module V1
    class ChatRoomMessagesController < ApplicationController
      before_action :set_users, only: [:create, :index]
      before_action :authorize

      def index
        phone_numbers = [@user1.phone_number.last(3), @user2.phone_number.last(3)].sort!
        chat_room_id = ChatRoom.where(name: phone_numbers.join('-')).pluck(:id)

        # if params[:chat_room_id].present?
        #   @chat_room_messages = ChatRoomMessage.where(chat_room_id: params[:chat_room_id]).order('created_at ASC')
        # end
        if chat_room_id.present?
          sender_chat_id = ChatRoomParticipant.where(chat_room_id: chat_room_id, user_id: @user1.id).pluck(:id)[0]
          @chat_room_messages = ChatRoomMessage.where(chat_room_id: chat_room_id).order('created_at ASC')
        end
        if @chat_room_messages.present?
          render json: {messages: @chat_room_messages, sender_chat_id: sender_chat_id}
        else
          render json: { message: 'You have no conversation with this user' }
        end
      end

      def create
        render json: { message: 'Invalid User' }, status: :unprocessable_entity and return unless @user1 && @user2

        @message, @chat_room = ChatSearchService.new(sender: @user1, receiver: @user2,
                                                     message_params: message_params).search
        if @message.save
          # ChatRoomChannel.broadcast_to( @chat_room.id, @message.body)
          ActionCable.server.broadcast "chat_room_#{@chat_room}", @message
          render json: @message.body
        else
          render json: @message.errors.full_messages, status: :unprocessable_entity
        end
      end

      private

      def message_params
        params.permit(:body)
      end

      def set_users
        authorize
        if params[:phone_number].present?
          # @user1 = User.find_by(id: params[:user_id])
          @user1 = @user
          @user2 = User.find_by(phone_number: get_phone_number)
        else
          render json: { message: 'Please Enter a Valid Phone Number' }
        end
      end
    end
  end
end
