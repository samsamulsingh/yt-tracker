alias YtTracker.Repo
alias YtTracker.Channels.YoutubeChannel
import Ecto.Query

# Manual fix for the Shoagsikdar channel
# Replace "Shoagsikdar" with the actual UC channel ID

# The real channel ID for @Shoagsikdar (you need to find this from YouTube)
# You can find it by:
# 1. Going to https://www.youtube.com/@Shoagsikdar
# 2. View page source
# 3. Search for "channelId" or "externalId"
# 4. Or use: https://www.youtube.com/@Shoagsikdar/about and inspect the RSS link

# For now, let's just show what needs to be fixed
channel = Repo.one(from c in YoutubeChannel, where: c.youtube_id == "Shoagsikdar")

if channel do
  IO.puts("Found channel with handle as ID:")
  IO.puts("  Current youtube_id: #{channel.youtube_id}")
  IO.puts("  Current rss_url: #{channel.rss_url}")
  IO.puts("")
  IO.puts("To fix this:")
  IO.puts("1. Visit https://www.youtube.com/@Shoagsikdar")
  IO.puts("2. Right-click → View Page Source")
  IO.puts("3. Search for 'externalId' or 'channelId'")
  IO.puts("4. Copy the UC... channel ID")
  IO.puts("5. Update this script with the real channel ID")
  IO.puts("")
  IO.puts("Or just use the 'Refresh Channel Info' button on the channel page!")
else
  IO.puts("Channel 'Shoagsikdar' not found. It may have already been fixed!")
end
