require 'rails_helper'

class NotFoundRedirectsController < ApplicationController
  include ShiftCommerce::NotFoundRedirects
  include ShiftCommerce::ResourceUrl

  def index
    get_static_page
    render empty: true
  end

  private

  def get_static_page
    FlexCommerce::StaticPage.includes([]).find(1).first
  end

  # Overrides NotFoundRedirects#handle_not_found
  # Avoid the test being stopped prematureiy by a real exception.
  def handle_not_found(exception = nil)
    false
  end
end

describe ShiftCommerce::NotFoundRedirects, type: :controller do

  before do
    stub_request(:get, /.*\/testaccount\/v1\/static_pages\/1\.json_api/).
      to_return(status: 404, body: '', headers: { 'Content-Type': 'application/vnd.api+json' })

    @controller = NotFoundRedirectsController.new

    Rails.application.routes.draw do
      get '/' => 'not_found_redirects#index'
    end
  end

  context 'when accessing a nonexistent resource' do
    context 'with a valid exact path redirect' do
      before do
        EXACT_REDIRECT = {
          data: {
            "id": "1",
            "type": "redirects",
            "links": {
              "self": "/testaccount/v1/redirects/1.json_api"
            },
            "attributes": {
              "name": "Redirect Name",
              "status_code": 301,
              "priority": 0,
              "source_type": "exact",
              "destination_type": "exact",
              "source_path": "/",
              "source_slug": "",
              "destination_path": "/somewhere_else",
              "destination_slug": ""
            }
          },
          meta: {
            total_entries: 1,
            page_count: 1
          },
          links: []
        }.to_json.freeze

        stub_request(:get, /.*\/testaccount\/v1\/redirects\.json_api/).
        to_return(status: 200, body: EXACT_REDIRECT, headers: { 'Content-Type': 'application/vnd.api+json' })
      end

      it "should redirect correctly" do
        get :index

        expect(response).to redirect_to '/somewhere_else'
      end
    end

    context 'with a valid resource redirect' do
      before do
        RESOURCE_REDIRECT = {
          data: {
            "id": "1",
            "type": "redirects",
            "links": {
              "self": "/testaccount/v1/redirects/1.json_api"
            },
            "attributes": {
              "name": "Redirect Name",
              "status_code": 301,
              "priority": 0,
              "source_type": "exact",
              "destination_type": "products",
              "source_path": "/",
              "source_slug": "",
              "destination_path": "",
              "destination_slug": "/products/1"
            }
          },
          meta: {
            total_entries: 1,
            page_count: 1
          },
          links: []
        }.to_json.freeze

        stub_request(:get, /.*\/testaccount\/v1\/redirects\.json_api/).
        to_return(status: 200, body: RESOURCE_REDIRECT, headers: { 'Content-Type': 'application/vnd.api+json' })
      end

      it "should redirect correctly" do
        get :index

        expect(response).to redirect_to '/products/1'
      end
    end


    context 'with no redirect' do
      before do
        EMPTY_REDIRECT = {
          data: [],
          meta: {
            total_entries: 0,
            page_count: 0
          },
          links: []
        }.to_json.freeze

        stub_request(:get, /.*\/testaccount\/v1\/redirects\.json_api/).
        to_return(status: 200, body: EMPTY_REDIRECT, headers: { 'Content-Type': 'application/vnd.api+json' })
      end

      it "should raise an exception" do
        expect { controller.send(:get_static_page) }.to raise_error(FlexCommerceApi::Error::NotFound)
      end
    end
  end

end
