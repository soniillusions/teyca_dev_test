require 'sinatra'
require 'sequel'
require 'require_all'

DB = Sequel.sqlite('db/test.db')

set :database, { adapter: 'sqlite3', database: 'db/test.db' }

require_all 'models'

post '/calculate' do
	data = JSON.parse(request.body.read)
	user = User[data['user_id']]

	return status 404 if user.nil?

	positions = data['positions']
	template = Template[user.template_id]

	total_price = 0
	total_discount = 0
	total_cashback = 0
	noloyalty_total = 0
	positions_arr = []

	positions.each do |position|
		product = Product[position['id']]

		next unless product

		price = position['price'].to_f * position['quantity']
		total_price += price

		case product.type
		when 'noloyalty'
			noloyalty_total += price
			next
		when 'increased_cashback'
			product_cashback = product.value.to_i
			total_cashback += price * ((template.cashback + product_cashback) / 100.0)
			total_discount += price * (template.discount / 100.0)
		when 'discount'
			product_discount = product.value.to_i
			total_discount += price * ((template.discount + product_discount) / 100.0)
			total_cashback += price * (template.cashback / 100.0)
		else
			total_discount += price * (template.discount / 100.0)
			total_cashback += price * (template.cashback / 100.0)
		end

		product_discount = product.type == 'discount' ? product.value.to_i : 0
		product_discount_percent = template.discount + product_discount

		positions_arr << {
			type: product.type,
			amount: position['quantity'],
			description: product.name,
			product_discount_percent: product_discount_percent,
			product_discount_value: total_discount
		}
	end

	final_price = total_price - total_discount
	allowed_write_off = final_price - noloyalty_total
	cashback_percent = ((total_cashback.to_f / total_price) * 100.0).round(2)
	discount_percent = ((total_discount.to_f / total_price) * 100.0).round(2)

	operation = Operation.create(
		user_id: user.id,
		check_summ: final_price,
		discount: total_discount,
		discount_percent: discount_percent,
		cashback: total_cashback,
		cashback_percent: cashback_percent,
		done: false,
		allowed_write_off: allowed_write_off
	)

	{
		status: 'success',
		user: { id: user.id, name: user.name },
		operation_id: operation.id,
		sum: final_price.round(2),
		bonus_information: {
			bonus_balance: user.bonus.to_f, 
			allowed_write_off: allowed_write_off, 
			cashback_percent: cashback_percent, 
			will_be_charged: total_cashback.round(2)
		},
		discount_information: {
			discount: total_discount.round(2),
			discount_percent: discount_percent,
		},
		positions: positions_arr
	}.to_json
end

post '/confirm' do
	data = JSON.parse(request.body.read)
	user = User[data['user']['id']]
	operation = Operation[data['operation_id']]

	return { status: 'error', message: 'Пользователь или операция не найдены' }.to_json if user.nil? || operation.nil?
	return { status: 'error', message: 'Операция уже выполнена' }.to_json if operation.done

    write_off = data['write_off'].to_f

    if write_off > operation.allowed_write_off
      return { status: 'error', message: 'Нельзя списать столько бонусов' }.to_json
    end

    new_final_price = (operation.check_summ - write_off).to_f.round(2)
    new_cashback = (new_final_price * (operation.cashback_percent / 100.0)).to_f.round(2)

	operation.update(
		check_summ: new_final_price,
		write_off: write_off,
		done: true
	)

	user.update(bonus: user.bonus - write_off + new_cashback)

	{
		status: 'confirmed',
		message: 'Операция успешно подтверждена',
		operation_info: {
			user_id: user.id,
			cashback_bonus: new_cashback,
			cashback_percent: operation.cashback_percent.to_f.round(2),
			total_discount: operation.discount.to_f.round(2),
			discount_percent: operation.discount_percent.to_f.round(2),
			write_off: write_off,
			final_sum_to_pay: new_final_price
		}
	}.to_json
end