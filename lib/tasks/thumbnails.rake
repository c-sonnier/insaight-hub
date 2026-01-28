namespace :thumbnails do
  desc "Generate missing thumbnails for all insight items"
  task generate_missing: :environment do
    insights_without_thumbnails = InsightItem
      .left_joins(:thumbnail_attachment)
      .where(active_storage_attachments: { id: nil })
      .where(thumbnail_generating: false)

    total = insights_without_thumbnails.count

    if total.zero?
      puts "All insight items already have thumbnails."
      next
    end

    puts "Found #{total} insight item(s) without thumbnails. Enqueueing generation jobs..."

    insights_without_thumbnails.find_each.with_index do |insight_item, index|
      insight_item.enqueue_thumbnail_generation!
      puts "  [#{index + 1}/#{total}] Enqueued: #{insight_item.title} (#{insight_item.slug})"
    end

    puts "\nDone! #{total} thumbnail generation job(s) enqueued."
    puts "Jobs will process in the background. Run 'bin/jobs' to start the job runner if not already running."
  end

  desc "Regenerate all thumbnails (useful after changing thumbnail generation logic)"
  task regenerate_all: :environment do
    total = InsightItem.count

    if total.zero?
      puts "No insight items found."
      next
    end

    print "This will regenerate thumbnails for all #{total} insight item(s). Continue? [y/N] "
    confirmation = $stdin.gets.chomp.downcase

    unless confirmation == "y"
      puts "Aborted."
      next
    end

    puts "Enqueueing thumbnail generation for #{total} insight item(s)..."

    InsightItem.find_each.with_index do |insight_item, index|
      insight_item.enqueue_thumbnail_generation!
      puts "  [#{index + 1}/#{total}] Enqueued: #{insight_item.title} (#{insight_item.slug})"
    end

    puts "\nDone! #{total} thumbnail generation job(s) enqueued."
  end
end
