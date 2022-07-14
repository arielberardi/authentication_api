class AccountsController < ApplicationController
  before_action :authenticate_user!, only: %i[show update destroy]
  before_action :verify_ownership!, only: %i[show update destroy]

  # GET /accounts/1
  def show
    render json: @current_account.filtered
  end

  # POST /accounts
  def create
    @account = Account.new(account_params)

    if @account.save
      send_activation_email
      render json: @account.filtered, status: :created
    else
      render json: @account.errors, status: :unprocessable_entity
    end
  end

  # GET /accounts/1/activate/:token
  def activate
    if TokensManager::activation_valid?(params[:id], params[:token])
      @account = Account.find(params[:id])
      @account.update(activated: true)
      render json: { message: 'Account activated' }
    else
      render json: { error: 'Invalid token' }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /accounts/1
  def update
    if @current_account.update(editable_params)
      render json: @current_account.filtered
    else
      render json: @current_account.errors, status: :unprocessable_entity
    end
  end

  # GET /accounts/1/unlock/:token
  def unlock
    if TokensManager::unlock_valid?(params[:id], params[:token])
      @account = Account.find(params[:id])
      @account.update(locked: false)
      render json: { message: 'Account unlocked' }
    else
      render json: { error: 'Invalid token' }, status: :unprocessable_entity
    end
  end

  # PATCH /accounts/1/reset_password/:token
  def reset_password
    if TokensManager::recovery_valid?(params[:id], params[:token])
      @account = Account.find(params[:id])
      if @account&.update(reset_password_params)
        render json: { message: 'Account updated' }
      else
        render json: @account.errors, status: :unprocessable_entity
      end
    else
      render json: { error: 'Invalid token' }, status: :unprocessable_entity
    end
  end

  # DELETE /accounts/1
  def destroy
    @current_account.destroy
  end

  private

  def reset_password_params
    params.require(:account).permit(:password, :password_confirmation)
  end

  def account_params
    params.require(:account)
          .permit(:email, :password, :password_confirmation, :first_name, :last_name)
  end

  def editable_params
    params.require(:account)
          .permit(:password, :password_confirmation, :first_name, :last_name)
  end

  def send_activation_email
    token = Account.generate_unique_secure_token

    TokensManager::add_to_activationlist(@account.id, token)

    AccountsMailer.activation(@account, token).deliver_later
  end
end
