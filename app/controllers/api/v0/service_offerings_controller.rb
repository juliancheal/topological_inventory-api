module Api
  module V0
    class ServiceOfferingsController < ApplicationController
      include Api::Mixins::IndexMixin
      include Api::Mixins::ShowMixin

      private

      def list_params
        params.permit(:source_id, :tenant_id)
      end

      def model
        ServiceOffering
      end
    end
  end
end
