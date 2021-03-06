class TransactionsController < ApplicationController
  #before_action :set_transaction, only: [:show, :edit, :update, :destroy]
  layout 'application', only: [:index, :details]
  skip_before_action :authenticate_user!
  # GET /transactions
  # GET /transactions.json
  def index
    @ress = Transaction.all
  end

  # GET /transactions/1
  # GET /transactions/1.json
  def details
    @res = Transaction.find(params[:id])
  end

  def callback
    res = 0;
    @paystackObj = Paystack.new(ENV['PUBLIC_KEY'], ENV['SECRET_KEY'])
   
    transaction_reference = params[:trxref]
  transactions = PaystackTransactions.new(@paystackObj)
  result = transactions.verify(transaction_reference)
  if result['data']['status'] == "success"
     @res = result['data']
     @customer = result['data']['customer']
      current_user.lawfirm.update(status: 1 )
      if current_user.lawfirm.interval == "monthly"
         res = 30
       elsif current_user.lawfirm.interval == "quarterly"
         res = 90
       elsif current_user.lawfirm == "annually"
          res = 365
      end

        if current_user.lawfirm.transactions.any?
          if current_user.lawfirm.transactions.last.expires_on > Date.today
          
              rem = (current_user.lawfirm.transactions.last.expires_on - Date.today).to_s.split('/')
              offset = rem[0].to_i + res


              @transaction = current_user.lawfirm.transactions.create(amount: (@res['amount'].to_f)/100,
              channel: @res['channel'], reference: @res['reference'], status: "success", gateway_response: @res['gateway_response'],
              currency: @res['currency'], status: @res['status'], expires_on: Date.today + offset.days,
              created_at: Time.now, updated_at: Time.now)

              redirect_to details_transaction_path(@transaction), notice: 'Your Subscription Upgrade was successful.'

          else
             @transaction = current_user.lawfirm.transactions.create(amount: (@res['amount'].to_f)/100,
          channel: @res['channel'], reference: @res['reference'], status: "success", gateway_response: @res['gateway_response'],
          currency: @res['currency'], status: @res['status'], expires_on: Date.today + res.days,
          created_at: Time.now, updated_at: Time.now)

            redirect_to details_transaction_path(@transaction), notice: 'Your Subscription was successful.'
          end

      
      else

        @transaction =  current_user.lawfirm.transactions.create(amount: (@res['amount'].to_f)/100,
          channel: @res['channel'], reference: @res['reference'], status: "success", gateway_response: @res['gateway_response'],
          currency: @res['currency'], status: @res['status'], expires_on: Date.today + res.days,
          created_at: Time.now, updated_at: Time.now)

        redirect_to details_transaction_path(@transaction), notice: 'Your Subscription was successful.'
       end
        
   
  else
    redirect_to new_transaction_path, notice: 'Payment Failed. Please try again'
  end

  end

  def show
  res = 0;
    @paystackObj = Paystack.new(ENV['PUBLIC_KEY'], ENV['SECRET_KEY'])
   
    transaction_reference = params[:trxref]
  transactions = PaystackTransactions.new(@paystackObj)
  result = transactions.verify(transaction_reference)
  if result['data']['status'] == "success"
     @res = result['data']
     @customer = result['data']['customer']
      current_user.lawfirm.update(status: 1 )
      if current_user.lawfirm.interval == "monthly"
         res = 30
       elsif current_user.lawfirm.interval == "quarterly"
         res = 90
       elsif current_user.lawfirm == "annually"
          res = 365
      end

         if current_user.lawfirm.transactions.any?
          if current_user.lawfirm.transactions.last.expires_on > Date.today
          
              rem = (current_user.lawfirm.transactions.last.expires_on - Date.today).to_s.split('/')
              offset = rem[0].to_i + res


              @transaction = current_user.lawfirm.transactions.create(amount: (@res['amount'].to_f)/100,
              channel: @res['channel'], reference: @res['reference'], status: "success", gateway_response: @res['gateway_response'],
              currency: @res['currency'], status: @res['status'], expires_on: Date.today + offset.days,
              created_at: Time.now, updated_at: Time.now)

              redirect_to details_transaction_path(@transaction), notice: 'Your Subscription Upgrade was successful.'

          else
             @transaction = current_user.lawfirm.transactions.create(amount: (@res['amount'].to_f)/100,
              channel: @res['channel'], reference: @res['reference'], status: "success", gateway_response: @res['gateway_response'],
              currency: @res['currency'], status: @res['status'], expires_on: Date.today + res.days,
              created_at: Time.now, updated_at: Time.now)

            redirect_to details_transaction_path(@transaction), notice: 'Your Subscription was successful.'
          end

      
      else

        @transaction =  current_user.lawfirm.transactions.create(amount: (@res['amount'].to_f)/100,
          channel: @res['channel'], reference: @res['reference'], status: "success", gateway_response: @res['gateway_response'],
          currency: @res['currency'], status: @res['status'], expires_on: Date.today + res.days,
          created_at: Time.now, updated_at: Time.now)

        redirect_to details_transaction_path(@transaction), notice: 'Your Subscription was successful.'
       end
   
  else
    redirect_to new_transaction_path, notice: 'Payment Failed. Please try again'
  end
  end


  # GET /transactions/new
  def new
    @paystackObj = Paystack.new(ENV['PUBLIC_KEY'], ENV['SECRET_KEY'])
    page_number = 1
    plans = PaystackPlans.new(@paystackObj)
    result = plans.list(page_number)  #Optional `page_number` parameter,  50 items per page
    @plans_list = result['data']
    @transaction = Transaction.new
  
  end

  def upgrade

     @paystackObj = Paystack.new(ENV['PUBLIC_KEY'], ENV['SECRET_KEY'])
    page_number = 1
    plans = PaystackPlans.new(@paystackObj)
    result = plans.list(page_number)  #Optional `page_number` parameter,  50 items per page
    @plans_list = result['data']
    @transaction = Transaction.new
    
  end


  # GET /transactions/1/edit
  def edit
  end

  
  # POST /transactions
  # POST /transactions.json
  def create

   current_user.lawfirm.update(interval: params[:interval] )
    new
    transactions = PaystackTransactions.new(@paystackObj)
    result = transactions.initializeTransaction(
    
    :email => current_user.lawfirm.email,
    :plan => params[:code]
    )
  auth_url = result['data']['authorization_url']

  redirect_to auth_url
  end

  # PATCH/PUT /transactions/1
  # PATCH/PUT /transactions/1.json
  def update
    respond_to do |format|
      if @transaction.update(transaction_params)
        format.html { redirect_to @transaction, notice: 'transaction was successfully updated.' }
        format.json { render :show, status: :ok, location: @transaction }
      else
        format.html { render :edit }
        format.json { render json: @transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /transactions/1
  # DELETE /transactions/1.json
  def destroy
    @transaction.destroy
    respond_to do |format|
      format.html { redirect_to transactions_url, notice: 'transaction was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_transaction
      @Transaction = Transaction.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def transaction_params
      params.require(:transaction).permit!
    end
end
