class TeamsController < ApplicationController
  before_action :set_team,  only: [:show, :edit, :update, :destroy]
  before_action :set_users, only: [:new, :edit]
  before_action :set_display_roles, only: :index

  load_and_authorize_resource except: [:index, :show]

  def index
    if params[:sort]
      direction = params[:direction] == 'asc' ? 'ASC' : 'DESC'
      @teams = Team.by_season_phase.includes(:activities).order("teams.kind, activities.created_at #{direction}").references(:activities)
    else
      @teams = Team.by_season_phase.order(:kind, :name)
    end
  end

  def show
  end

  def new
    @team = Team.new
    @team.roles.build(name: 'student', github_handle: current_user.github_handle)
    @team.sources.build(kind: 'blog')
  end

  def edit
    @team.sources.build(kind: 'blog') unless @team.sources.any?
    @team.build_project unless @team.project
  end

  def create
    @team = Team.new(team_params)
    @team.season = current_season

    respond_to do |format|
      if @team.save
        format.html { redirect_to @team, notice: 'Team was successfully created.' }
        format.json { render action: :show, status: :created, location: @team }
      else
        format.html { render action: :new }
        format.json { render json: @team.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @team.update_attributes(team_params)
        format.html { redirect_to @team, notice: 'Team was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: :edit }
        format.json { render json: @team.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @team.destroy
    respond_to do |format|
      format.html { redirect_to teams_url }
      format.json { head :no_content }
    end
  end

  private

    def set_team
      @team = Team.find(params[:id])
    end

    def set_users
      @users = User.order(:github_handle)
    end

    def team_params
      params[:team].fetch(:sources_attributes, {}).delete_if { |key, source| source[:url].empty? }
      params.require(:team).permit(
        :name, :twitter_handle, :github_handle, :description, :post_info, :event_id,
        :checked, :'starts_on(1i)', :'starts_on(2i)', :'starts_on(3i)',
        :'finishes_on(1i)', :'finishes_on(2i)', :'finishes_on(3i)', :invisible,
        :project_name,
        roles_attributes: [:id, :name, :github_handle, :_destroy],
        sources_attributes: [:id, :kind, :url, :_destroy]
      )
    end

  def set_display_roles
    @display_roles = ['student']
    @display_roles.map!(&:pluralize)
  end
end
