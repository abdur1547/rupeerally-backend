# frozen_string_literal: true

module Api::V0::Transfers
  class Create
    include ApplicationService

    class Contract < ApplicationContract
      params do
        required(:from_account_id).filled(:integer)
        required(:to_account_id).filled(:integer)
        required(:description).filled(:string)
        required(:amount_cents).filled(:integer)
      end
    end

    def execute(params, current_user:)
      @params = params
      @current_user = current_user

      yield validate_not_same_account
      yield validate_from_account_id
      yield validate_to_account_id
      transfer = yield create_transfer
      Success(json_serialize(transfer))
    end

    private

    attr_reader :current_user, :params, :from_account, :to_account

    def validate_not_same_account
      return Success() unless params[:from_account_id] == params[:to_account_id]

      Failure('Transfer should have two different accounts')
    end

    def validate_from_account_id
      @from_account = current_user.accounts.find_by(id: params[:from_account_id])
      return Success(from_account) if from_account

      Failure(:from_account_not_found)
    end

    def validate_to_account_id
      @to_account = current_user.accounts.find_by(id: params[:to_account_id])
      return Success(to_account) if to_account

      Failure(:to_account_not_found)
    end

    def create_transfer
      result = ::TransferService::Create.call(create_params)
      return Failure(result[:errors]) unless result[:success]

      transfer = result[:transfer]
      Success(transfer)
    end

    def create_params
      {
        current_user:,
        from_account:,
        to_account:,
        description: params[:description],
        amount_cents: params[:amount_cents]
      }
    end

    def json_serialize(records)
      Api::V0::TransfersSerializer.render_as_hash([records])
    end
  end
end
