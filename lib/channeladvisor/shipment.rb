module ChannelAdvisor
  class Shipment < Base
    attr_accessor :shipping_carrier, :shipping_class, :tracking_number

    def initialize(attrs={})
      @shipping_carrier = attrs[:shipping_carrier]
      @shipping_class   = attrs[:shipping_class]
      @tracking_number  = attrs[:tracking_number]
    end

    # Submit shipments for one or more orders. When called with a single shipment the return
    # value will be a single boolean value, otherwise a hash of value will be returned.
    #
    # @param [Hash, Array<Hash>] shipment_data A shipment hash or array of shipment hashes
    #
    # @raise [ServiceFailure] If the service returns a Failure status
    # @raise [SOAPFault] If the service responds with a SOAP fault
    # @raise [HTTPError] If the service responds with an HTTP error
    #
    # @return [Boolean, Hash] Returns a boolean or a hash of order IDs and their corresponding boolean results
    def self.submit(shipment_data)
      handle_errors do
        shipments = arrayify(shipment_data)

        shipments.each do |shipment|
          shipment[:type] = shipment[:line_items] ? "Partial" : "Full"
          shipment[:date] ||= DateTime.now
          shipment[:cost]       = "%.2f" % shipment[:cost].to_f
          shipment[:tax]        = "%.2f" % shipment[:tax].to_f
          shipment[:insurance]  = "%.2f" % shipment[:insurance].to_f
        end

        response = Services::ShippingService.submit_order_shipment_list(shipments)
        result = response[:submit_order_shipment_list_response][:submit_order_shipment_list_result]
        check_status_of result

        shipment_responses = arrayify result[:result_data][:shipment_response]

        if shipment_responses.count == 1
          return shipment_responses.first[:success]
        else
          result_hash = {}

          shipment_responses.each do |shipment_response|
            shipments.each do |shipment|
              result_hash[shipment[:order_id].to_s] = shipment_response[:success]
            end
          end

          return result_hash
        end
      end
    end # self.submit

    # Get a list of all valid shipping carriers and classes
    #
    # @raise [ServiceFailure] If the service returns a Failure status
    # @raise [SOAPFault] If the service responds with a SOAP fault
    # @raise [HTTPError] If the service responds with an HTTP error
    #
    # @return [Array<Hash>] An array of shipping carrier hashes
    def self.get_carriers
      handle_errors do
        response = Services::ShippingService.get_shipping_carrier_list
        result = response[:get_shipping_carrier_list_response][:get_shipping_carrier_list_result]
        check_status_of result
        arrayify result[:result_data][:shipping_carrier]
      end
    end # self.get_carriers
  end # Shipment
end # ChannelAdvisor