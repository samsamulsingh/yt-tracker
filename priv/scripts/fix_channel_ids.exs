alias YtTracker.Repo
alias YtTracker.Channels.YoutubeChannel
alias YtTracker.YoutubeApi
import Ecto.Query

# Find channels that might have handles instead of channel IDs
channels = Repo.all(
  from c in YoutubeChannel,
  where: not like(c.youtube_id, "UC%")
)

IO.puts("Found #{length(channels)} channels with non-standard IDs (possibly handles)")

Enum.each(channels, fn channel ->
  IO.puts("\nProcessing channel: #{channel.youtube_id}")
  
  case YoutubeApi.get_channel(channel.youtube_id) do
    {:ok, channel_data} ->
      real_channel_id = channel_data.youtube_id
      IO.puts("  ✓ Found real channel ID: #{real_channel_id}")
      IO.puts("  ✓ Title: #{channel_data.title}")
      
      # Update the channel with the real ID and RSS URL
      rss_url = YoutubeChannel.rss_url(real_channel_id)
      
      channel
      |> YoutubeChannel.changeset(%{
        youtube_id: real_channel_id,
        rss_url: rss_url,
        title: channel_data.title,
        description: channel_data.description,
        thumbnail_url: channel_data.thumbnail_url,
        uploads_playlist_id: channel_data.uploads_playlist_id,
        subscriber_count: channel_data.subscriber_count,
        video_count: channel_data.video_count,
        view_count: channel_data.view_count
      })
      |> Repo.update()
      
      IO.puts("  ✓ Updated with real channel ID and metadata")
      IO.puts("  ✓ RSS URL: #{rss_url}")
      
    {:error, reason} ->
      IO.puts("  ✗ Failed to fetch channel: #{inspect(reason)}")
  end
end)

IO.puts("\nDone!")
