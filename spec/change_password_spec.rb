require 'spec_helper'

module AccountManager

  describe 'a user changes their password', type: :request do

    before :all do
      start_ladle
      load_fixtures
    end

    after :all do
      stop_ladle
    end

    context 'when their account is already activated' do

      before :all do
        @uid, @new_password = 'bb459', 'Strong Enough!'
        submit_change_password_form(
          uid: @uid,
          password: 'niwdlab',
          new_password: @new_password
        )
      end

      it 'reports success' do
        page.should have_content 'Your password has been changed'
      end

      it 'changes the password' do
        Directory.can_bind?(@uid, @new_password).should be true
      end

      it 'does not change the "ituseagreeementacceptdate" timestamp' do
        Directory.search "(uid=#{@uid})" do |entry|
          entry[:ituseagreementacceptdate].should == @users[@uid][:ituseagreementacceptdate]
        end
      end

      it 'changes the "passwordchangedate" timestamp' do
        Directory.search "(uid=#{@uid})" do |entry|
          entry[:passwordchangedate].should_not == @users[@uid][:passwordchangedate]
        end
      end
    end

    context 'when their account is not activated' do

      before :all do
        @uid, @new_password = 'cc414', 'new_password'
        submit_change_password_form(
          uid: @uid,
          password: 'retneprac',
          new_password: @new_password
        )
      end

      it 'reports success' do
        page.should have_content 'Your password has been changed'
      end

      it 'changes the password' do
        Directory.can_bind?(@uid, @new_password).should be true
      end

      it 'activates the account' do
        Directory.activated?(@uid).should be true
      end

      it 'sets a "passwordchangedate" timestamp' do
        Directory.search "(uid=#{@uid})" do |entry|
          entry[:passwordchangedate].first.should match /\d{14}Z/
        end
      end
    end

    context 'when the account does not exist' do

      it 'reports failure' do
        submit_change_password_form(
          uid: 'nobody',
          password: '',
          new_password: 'Strong Enough!'
        )
        page.should have_content 'Your username or password was incorrect'
      end
    end

    context 'when their password is wrong' do

      before :all do
        @uid = 'aa729'
        submit_change_password_form(
          uid: @uid,
          password: 'bad_password',
          new_password: 'new_password'
        )
      end

      it 'reports failure' do
        page.should have_content 'Your username or password was incorrect'
      end

      it 'does not modify the user' do
        should_not_modify @uid
      end
    end

    context "when their verify_password field doesn't match" do

      before :all do
        @uid = 'aa729'
        submit_change_password_form(
          uid: @uid,
          password: 'smada',
          new_password: 'new_password',
          verify_password: 'bad_password'
        )
      end

      it 'reports failure' do
        page.should have_content 'Your new passwords do not match'
      end

      it 'does not modify the user' do
        should_not_modify @uid
      end
    end

    context "when they don't agree to the terms and conditions" do

      before :all do
        @uid = 'aa729'
        submit_change_password_form(
          uid: @uid,
          password: 'smada',
          new_password: 'new_password',
          disagree: true
        )
      end

      it 'reports failure' do
        page.should have_content 'You must agree to the terms and conditions'
      end

      it 'does not modify the user' do
        should_not_modify @uid
      end
    end

    context 'when their account is inactive and their password is wrong' do

      before :all do
        @uid = 'dd945'
        submit_change_password_form(
          uid: @uid,
          password: 'bad_password',
          new_password: 'new_password',
        )
      end

      it 'reports failure' do
        page.should have_content 'Your username or password was incorrect'
      end

      it 'does not modify the user' do
        should_not_modify @uid
      end
    end

    context 'when their password is weak' do

      before :all do
        @uid = 'hh153'
        submit_change_password_form(
          uid: @uid,
          password: 'dleiftah',
          new_password: 'weak'
        )
      end

      it 'reports failure' do
        page.should have_content 'Your new password is too weak'
      end

      it 'does not modify the user' do
        should_not_modify @uid
      end
    end

    context 'when their password is strong' do

      before :all do
        @uid, @new_password = 'ii711', 'Strong Pa55word!'
        submit_change_password_form(
          uid: @uid,
          password: 'margni',
          new_password: @new_password
        )
      end

      it 'reports success' do
        page.should have_content 'Your password has been changed'
      end

      it 'changes the password' do
        Directory.can_bind?(@uid, @new_password).should be true
      end
    end
  end
end
