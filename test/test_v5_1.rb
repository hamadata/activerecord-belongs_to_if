# frozen_string_literal: true

begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"

  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  # Activate the gem you are reporting the issue against.
  gem "activerecord", "5.1.6"
  gem "sqlite3"
  gem "activerecord-belongs_to_if", path: './'
  gem 'byebug'
end

require "active_record"
require "minitest/autorun"
require "logger"
require "activerecord-belongs_to_if"
require 'byebug'

# Ensure backward compatibility with Minitest 4
Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)

# This connection will do for database-independent bug reports.
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
  end

  create_table :activities, force: true do |t|
    t.string :activitable_type
    t.bigint :activitable_id
    t.references :user
  end

  create_table :comments, force: true do |t|
    t.references :owner
  end

  create_table :issues, force: true do |t|
    t.references :owner
  end

  create_table :pull_requests, force: true do |t|
    t.references :owner
  end
end

class User < ActiveRecord::Base
  has_many :activities
end

class Activity < ActiveRecord::Base
  belongs_to :user
  belongs_to :comment, if: -> { activitable_type == 'Comment' }, foreign_key: :activitable_id, class_name: 'Comment'
  belongs_to :issue, if: -> { activitable_type == 'Issue' }, foreign_key: :activitable_id, class_name: 'Issue'
  belongs_to :pull_request, if: -> { activitable_type == 'PullRequest' }, foreign_key: :activitable_id, class_name: 'PullRequest'
end

class Comment < ActiveRecord::Base
  has_many :activities, as: :activitable
  belongs_to :owner, class_name: 'User'
end

class Issue < ActiveRecord::Base
  has_many :activities, as: :activitable
  belongs_to :owner, class_name: 'User'
end

class PullRequest < ActiveRecord::Base
  has_many :activities, as: :activitable
  belongs_to :owner, class_name: 'User'
end

class BugTest < Minitest::Test
  def test_association_stuff
    ActiveRecord::Base.transaction do
      @user = User.create
      Comment.create(owner: User.create()).activities << Activity.create(user: @user)
      Comment.create(owner: User.create()).activities << Activity.create(user: @user)
      Comment.create(owner: User.create()).activities << Activity.create(user: @user)

      Issue.create(owner: User.create()).activities << Activity.create(user: @user)
      Issue.create(owner: User.create()).activities << Activity.create(user: @user)
      Issue.create(owner: User.create()).activities << Activity.create(user: @user)

      PullRequest.create(owner: User.create()).activities << Activity.create(user: @user)
      PullRequest.create(owner: User.create()).activities << Activity.create(user: @user)
      PullRequest.create(owner: User.create()).activities << Activity.create(user: @user)
    end
    result = @user.activities.includes([
            {
                comment: :owner,
                issue: :owner,
                pull_request: :owner
            }
    ])
    puts 'result'
    result.each do |activity|
      if activity.activitable_type == 'Comment'
        puts activity.comment.inspect
        puts activity.comment.owner.inspect
      elsif activity.activitable_type == 'Issue'
        puts activity.issue.inspect
        puts activity.issue.owner.inspect
      elsif activity.activitable_type == 'PullRequest'
        puts activity.pull_request.inspect
        puts activity.pull_request.owner.inspect
      end
    end
  end
end