{ pkgs, config, lib, ... }:

{
  programs.newsboat = {
    enable = true;
    autoReload = true;
    urls = [
      { url = "http://feeds.feedburner.com/servethehome"; }
      { url = "https://weekly.nixos.org/feeds/all.rss.xml"; }
      { url = "http://www.willghatch.net/blog/feeds/all.rss.xml"; }
      { url = "https://jrs-s.net/feed/"; }
      { url = "http://blog.cmpxchg8b.com/feeds/posts/default"; }
      { url = "https://www.copetti.org/index.xml"; }
      { url = "https://www.home-assistant.io/atom.xml"; }
    ];
  };
}
