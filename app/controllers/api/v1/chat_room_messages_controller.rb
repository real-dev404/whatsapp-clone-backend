module Api
  module V1
    class ChatRoomMessagesController < ApplicationController
      before_action :set_users, only: [:create]
      before_action :check_session_token
      before_action :session_expiry

      include HandleSessionExpiryConcern

      def index
        @chat_room_messages = ChatRoomMessage.where(chat_room_id: params[:chat_room_id]).order("created_at ASC") if params[:chat_room_id].present?
        if @chat_room_messages.present?
          render json: @chat_room_messages
        else
          render json: { message: 'You have no conversation with this user' }
        end
      end

      def create
        render json: { message: 'Invalid User' }, status: 422 and return  unless @user1 && @user2

        @message, @chat_room = ChatSearchService.new(sender: @user1, receiver: @user2, message_params: message_params).search
        if @message.save
          ChatRoomChannel.broadcast_to(@message, @chat_room)
          render json: @message
        else
          render json: @message.errors.full_messages, status: 422
        end
      end

      private

      def message_params
        params.require(:chat_room_message).permit(:body)
      end

      def set_users
        if params[:user_id].present? && params[:phone_number].present?
          @user1 = User.find_by(id: params[:user_id])
          @user2 = User.find_by(phone_number: params[:phone_number])
        else
          render json: { message: 'Please Enter a Valid Phone Number' }
        end
      end

    end
  end
end
