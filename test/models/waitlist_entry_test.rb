require "test_helper"

class WaitlistEntryTest < ActiveSupport::TestCase
  test "valid with name and email" do
    entry = WaitlistEntry.new(name: "John Doe", email: "test@example.com")
    assert entry.valid?
  end

  test "invalid without name" do
    entry = WaitlistEntry.new(name: "", email: "test@example.com")
    assert_not entry.valid?
    assert_includes entry.errors[:name], "can't be blank"
  end

  test "invalid without email" do
    entry = WaitlistEntry.new(name: "John Doe", email: "")
    assert_not entry.valid?
    assert_includes entry.errors[:email], "can't be blank"
  end

  test "invalid with malformed email" do
    entry = WaitlistEntry.new(name: "John Doe", email: "not-an-email")
    assert_not entry.valid?
  end

  test "normalizes email to lowercase" do
    entry = WaitlistEntry.create!(name: "John Doe", email: "TEST@EXAMPLE.COM")
    assert_equal "test@example.com", entry.email
  end

  test "strips whitespace from email" do
    entry = WaitlistEntry.create!(name: "John Doe", email: "  test@example.com  ")
    assert_equal "test@example.com", entry.email
  end

  test "strips whitespace from name" do
    entry = WaitlistEntry.create!(name: "  John Doe  ", email: "test2@example.com")
    assert_equal "John Doe", entry.name
  end

  test "email must be unique" do
    WaitlistEntry.create!(name: "John Doe", email: "test@example.com")
    duplicate = WaitlistEntry.new(name: "Jane Doe", email: "test@example.com")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end
end
