defmodule YtTracker.Workers.PollRssTest do
  use YtTracker.DataCase
  use Oban.Testing, repo: YtTracker.Repo

  alias YtTracker.{Tenancy, Channels}
  alias YtTracker.Workers.PollRss

  setup do
    {:ok, tenant} = Tenancy.create_tenant(%{name: "Test", slug: "test"})
    {:ok, tenant: tenant}
  end

  describe "perform/1" do
    test "polls channels that need polling", %{tenant: tenant} do
      # Create a channel
      {:ok, channel} =
        Channels.create_channel(tenant.id, %{
          youtube_id: "UCtest123",
          title: "Test Channel",
          uploads_playlist_id: "UUtest123",
          rss_url: Channels.YoutubeChannel.rss_url("UCtest123")
        })

      # This would require mocking the RSS feed
      # For now, just ensure the job can be enqueued
      assert :ok = perform_job(PollRss, %{channel_id: channel.id})
    end
  end
end
