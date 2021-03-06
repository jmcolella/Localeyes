class TripsController < ApplicationController

  def index
    @trips_to_display = Trip.sort_by_favorites
    @search_results = false
  end

  def search
    @trips_to_display = Trip.filter_and_search(params[:search].split(" "), params[:city], params[:state], params[:trip][:country])
    @search_results = true if @trips_to_display != []
    render :template => 'trips/index'
  end

  def new
    @trip = Trip.new
    if !user_signed_in?
      redirect_to root_path
    end
  end

  def create
    @trip = Trip.new(trip_params)
    @trip.creator = current_user
    if params[ :trip ][ :tags ].include?( ", " )
      tags = params[ :trip ][ :tags ].split( ", " )
    else
      tags = params[ :trip ][ :tags ].split( " " )
    end
    tags = Tag.split_tags(params[ :trip ][ :tags ])

    if @trip.save
      tags.each do |tag|
        @trip.tags << Tag.find_create_tags(tag)
      end

      if @trip.tags.length < 1
        @trip.destroy
        @errors = [ "Trip must have at least one tag.", "Please add one tag to continue." ]
        render 'new'
      else
        redirect_to new_trip_location_path( @trip )
      end
    else
      @errors = [ "Trip name cannot be blank.", "Please add a name to continue." ]
      render 'new'
    end
  end

  def show
    @trip = Trip.find_by( id: params[ :id ] )

    if @trip == nil
      redirect_to new_trip_path
    else
      @locations = @trip.locations
      @comment = Comment.new
      @creator_comments = @trip.creator_comments
      @user_comments = @trip.user_comments

      if @trip.locations.length < 3
        redirect_to new_trip_location_path( @trip )
      end
    end
  end

  def coordinates
    trip = Trip.find_by( id: params[ :id ] )
    place = GOOGLE_CLIENT.spots_by_query( "#{trip.city}, #{trip.state}" )
    @coordinates = [ place.first.lat, place.first.lng ]

    if request.xhr?
      render partial: 'coordinates', layout: false, locals: { coordinates: @coordinates }
    end
  end

  def destroy
    @trip = Trip.find_by( id: params[ :id ] )
    @trip.destroy

    if request.xhr?
      render partial: "deleted_locations"
    end
  end

  private
    def trip_params
      params.require( :trip ).permit( :name, :city, :state, :country )
    end
end
