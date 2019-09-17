class AssetManagerRedirectController < ApplicationController
  def show
    asset_url = Plek.new.public_asset_host
    if request.host.start_with?("draft-")
      asset_url = Plek.new.external_url_for("draft-assets")
    end

    redirect_to host: URI.parse(asset_url).host, status: 301
  end
end
