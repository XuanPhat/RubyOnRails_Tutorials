module RailsAdmin
  module Config
    module Actions
      class Dashboard < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :root? do
          true
        end

        register_instance_option :breadcrumb_parent do
          nil
        end

        register_instance_option :controller do
          proc do
            # You can specify instance variables
            def orders(order_items)
              data = []
              order_items.pluck('product_order').each do |item|
                data << JSON.parse(item)
              end
              data.flatten
            end

            def have_params_month_year(product_id = {})
              products = ProductView.by_month_year(params['month_year'].split('-')[1],
                                                   params['month_year'].split('-')[0])
              product_view = products.present? && products.pluck('product_id').compact.each_with_object(Hash.new(0)) do |c, counts|
                                                    counts[c] += 1
                                                  end.max_by do |_k, v|
                                                    v
                                                  end [0]
              if product_id != {}
                products = Product.by_ids([product_id, product_view])
                result = products.find_by!(id: product_id)
              else
                products = Product.by_ids(product_view)
                result = nil
              end
              keywords = KeywordSearch.by_keywords(params['month_year'].split('-')[1],
                                                   params['month_year'].split('-')[0])
              {
                best_seller: result,
                best_keyword_search: keywords.present? ? keywords.find_by!(count: keywords.pluck('count').max) : nil,
                best_product_views: products.find_by(id: product_view),
                vouchers: Voucher.by_vouchers(params['month_year'].split('-')[1],
                                              params['month_year'].split('-')[0]).size
              }
            end

            def not_have_params_month_year(product_id = {})
              product_view = ProductView.by_month_year(Time.zone.now.month,
                                                       Time.zone.now.year)
                                        .pluck('product_id').compact.each_with_object(Hash.new(0)) do |c, counts|
                                          counts[c] += 1
                                        end.max_by do |_k, v|
                                          v
                                        end [0]
              products = Product.by_ids([product_id, product_view])
              keywords = KeywordSearch.by_keywords(Time.zone.now.month, Time.zone.now.year)

              {
                best_seller: Product.find(product_id),
                best_keyword_search: keywords.present? ? keywords.find_by!(count: keywords.pluck('count').max) : nil,
                best_product_views: products.find_by(id: product_view),
                vouchers: Voucher.by_vouchers(Time.zone.now.month, Time.zone.now.year).size
              }
            end

            def statistic_products(order_items = {}, month_year = {})
              if order_items.present? # have order item
                product_id = orders(order_items).pluck('id').each_with_object(Hash.new(0)) do |product, counts|
                               counts[product] += 1
                             end.max_by { |_k, v| v }[0]

                if month_year.present?
                  have_params_month_year(product_id)
                else
                  not_have_params_month_year(product_id)
                end
              elsif order_items.present? == false && month_year.present? == true # have order item && month_year exists
                have_params_month_year
              elsif order_items.present? == false && month_year.present? == false # have order item exists but month_year not exists
                not_have_params_month_year
              end
            end
            # You can access submitted params (just submit your form to the dashboard).
            if params[:month_year] # month_year exists
              year = params['month_year'].split('-')[0]
              month = params['month_year'].split('-')[1]
              order_items = OrderItem.this_status(Product::STATUS[:confirmed])
                                     .by_orders(month, year)
              fee_ship = order_items.pluck('fee').sum
              voucher = order_items.pluck('voucher').sum
              @result = {
                data: orders(order_items).pluck('total').sum + fee_ship - voucher,
                sold: orders(order_items).size,
                year: year,
                month: month,
                statistic_products: statistic_products(order_items, params[:month_year])
              }
            else # month_year not exists
              order_items = OrderItem.this_status(Product::STATUS[:confirmed])
                                     .by_orders(Time.zone.now.month, Time.zone.now.year)
              fee_ship = order_items.pluck('fee').sum
              voucher = order_items.pluck('voucher').sum
              @result = {
                data: orders(order_items).pluck('total').sum + fee_ship - voucher,
                sold: orders(order_items).size,
                year: Time.zone.now.year,
                month: Time.zone.now.month,
                statistic_products: statistic_products(order_items, {})
              }

            end
            # product sold of this month
            @total_availabilitys = Availability.all.size
            # You can specify flash messages
            flash.now[:success] = 'Welcome to dashboard'

            # After you're done processing everything, render the new dashboard
            render @action.template_name, status: 200
          end
        end

        register_instance_option :route_fragment do
          ''
        end

        register_instance_option :link_icon do
          'icon-home'
        end

        register_instance_option :statistics? do
          true
        end
      end
    end
  end
end
