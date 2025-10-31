alias YtTracker.Repo
alias YtTracker.Channels.YoutubeChannel
import Ecto.Query

# Update all channels that don't have rss_url set
channels_without_rss = Repo.all(
  from c in YoutubeChannel,
  where: is_nil(c.rss_url) or c.rss_url == ""
)

IO.puts("Found #{length(channels_without_rss)} channels without RSS URL")

Enum.each(channels_without_rss, fn channel ->
  rss_url = YoutubeChannel.rss_url(channel.youtube_id)
  IO.puts("Updating channel #{channel.youtube_id} with RSS URL: #{rss_url}")
  
  channel
  |> YoutubeChannel.changeset(%{rss_url: rss_url})
  |> Repo.update()
end)

IO.puts("Done!")
