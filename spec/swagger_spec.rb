describe "Swagger stuff" do
  let(:rails_routes) do
    Rails.application.routes.routes.each_with_object([]) do |route, array|
      r = ActionDispatch::Routing::RouteWrapper.new(route)
      next if r.internal? # Don't display rails routes
      next if r.engine? # Don't care right now...

      array << {:verb => r.verb, :path => r.path.split("(").first.sub(/:[_a-z]*id/, ":id")}
    end
  end

  let(:swagger_routes) { Api::Docs.routes }

  describe "Routing" do
    include Rails.application.routes.url_helpers

    it "routes match" do
      redirect_routes = [{:path=>"/api/v0/*path", :verb=>"DELETE|GET|OPTIONS|PATCH|POST|PUT"}]
      additional_routes = [{:path => "/api/v0.0/service_plans/:id/order", :verb => "POST"}]
      expect(rails_routes).to match_array(swagger_routes + redirect_routes + additional_routes)
    end

    context "customizable route prefixes" do
      before do
        stub_const("ENV", ENV.to_h.merge("PATH_PREFIX" => random_path))
        Rails.application.reload_routes!
      end

      after(:all) do
        Rails.application.reload_routes!
      end

      it "with a random prefix" do
        expect(ENV["PATH_PREFIX"]).not_to be_nil
        expect(api_v0x0_sources_url(:only_path => true)).to eq("/#{URI.encode(ENV["PATH_PREFIX"])}/v0.0/sources")
      end
    end

    def words
      @words ||= File.readlines("/usr/share/dict/words").collect(&:strip)
    end

    def random_path_part
      rand(1..5).times.collect { words.sample }.join("_")
    end

    def random_path
      rand(1..10).times.collect { random_path_part }.join("/")
    end
  end

  describe "Model serialization" do
    let(:doc) { Api::Docs[version] }
    let(:container_group) { ContainerGroup.create!(doc.example_attributes("ContainerGroup").symbolize_keys.merge(:tenant => tenant, :source => source, :container_node => container_node, :container_project => container_project, :source_created_at => Time.now, :source_ref => SecureRandom.uuid)) }
    let(:container_node) { ContainerNode.create!(doc.example_attributes("ContainerNode").symbolize_keys.merge(:tenant => tenant, :source => source, :source_ref => SecureRandom.uuid, :source_created_at => Time.now)) }
    let(:container_project) { ContainerProject.create!(doc.example_attributes("ContainerProject").symbolize_keys.merge(:tenant => tenant, :source => source, :source_ref => SecureRandom.uuid)) }
    let(:container_template) { ContainerTemplate.create!(doc.example_attributes("ContainerTemplate").symbolize_keys.merge(:tenant => tenant, :source => source, :container_project => container_project, :source_created_at => Time.now, :source_ref => SecureRandom.uuid)) }
    let(:endpoint) { Endpoint.create!(doc.example_attributes("Endpoint").symbolize_keys.merge(:tenant => tenant, :source => source)) }
    let(:orchestration_stack) { OrchestrationStack.create!(doc.example_attributes("OrchestrationStack").symbolize_keys.merge(:tenant => tenant, :source => source)) }
    let(:service_instance) { ServiceInstance.create!(doc.example_attributes("ServiceInstance").symbolize_keys.merge(:tenant => tenant, :source => source, :service_offering => service_offering, :service_plan => service_plan, :source_created_at => Time.now, :source_ref => SecureRandom.uuid, :source_region => source_region, :subscription => subscription)) }
    let(:service_offering) { ServiceOffering.create!(doc.example_attributes("ServiceOffering").symbolize_keys.merge(:tenant => tenant, :source => source, :source_ref => SecureRandom.uuid, :source_created_at => Time.now, :source_region => source_region, :subscription => subscription)) }
    let(:service_plan) { ServicePlan.create!(doc.example_attributes("ServicePlan").symbolize_keys.merge(:tenant => tenant, :source => source, :service_offering => service_offering, :source_ref => SecureRandom.uuid, :source_created_at => Time.now, :create_json_schema => {}, :update_json_schema => {}, :source_region => source_region, :subscription => subscription)) }
    let(:source) { Source.create!(doc.example_attributes("Source").symbolize_keys.merge(:source_type => source_type, :tenant => tenant, :uid => SecureRandom.uuid)) }
    let(:source_region) { SourceRegion.create!(:source => source, :tenant => tenant) }
    let(:source_type) { SourceType.create!(:name => "openshift", :product_name => "OpenShift", :vendor => "Red Hat") }
    let(:subscription) { Subscription.create!(:source => source, :tenant => tenant) }
    let(:vm) { Vm.create!(doc.example_attributes("Vm").symbolize_keys.merge(:source => source, :tenant => tenant, :source_ref => SecureRandom.uuid, :uid_ems => SecureRandom.uuid)) }
    let(:task) { Task.create!(:tenant => tenant, :name => "Operation", :status => "Ok", :state => "Running", :completed_at => Time.now.utc, :context => {:method => "order"}) }
    let(:tenant) { Tenant.create! }

    context "v0.0" do
      let(:version) { "0.0" }
      Api::Docs["0.0"].definitions.each do |definition_name, schema|
        next if definition_name.in?(["Id"])

        it "#{definition_name} matches the JSONSchema" do
          const = definition_name.constantize
          expect(send(definition_name.underscore).as_json(:prefixes => ["api/v0x0/#{definition_name.underscore}"])).to match_json_schema("0.0", definition_name)
        end
      end
    end
  end
end
