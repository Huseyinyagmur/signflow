module Api
  module V1
    class TemplateVersionsController < BaseController
      def show
        version = Templates::Manage.new(user: @credential.user).version(params[:template_id], params[:id])
        render json: { id: version.id, template_id: version.template_id, number: version.number,
          title: version.title, variables: version.variables }
      end
    end
  end
end
