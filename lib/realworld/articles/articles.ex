defmodule Realworld.Articles do
  use Ash.Domain, otp_app: :realworld

  authorization do
    authorize :by_default
  end

  resources do
    resource Realworld.Articles.Article do
      define :get_article_by_slug, action: :read, get_by: :slug
      define :list_articles
      define :destroy_article, action: :destroy
    end

    resource Realworld.Articles.ArticleTag

    resource Realworld.Articles.Comment do
      define :destroy_comment, action: :destroy
    end

    resource Realworld.Articles.Favorite do
      define :favorite, action: :add_favorite, args: [:article_id]

      define :unfavorite,
        action: :remove_favorite,
        args: [:article_id],
        require_reference?: false,
        get?: true

      define :favorited, action: :favorited, args: [:article_id]
    end

    resource Realworld.Articles.Tag do
      define :list_tags
    end
  end

  # Helper functions for the LiveView
  def favorite_article(slug, user) do
    case get_article_by_slug(slug, actor: user) do
      {:ok, article} ->
        favorite(user_id: user.id, article_id: article.id, actor: user)
      
      error ->
        error
    end
  end

  def unfavorite_article(slug, user) do
    case get_article_by_slug(slug, actor: user) do
      {:ok, article} ->
        unfavorite(user_id: user.id, article_id: article.id, actor: user)
      
      error ->
        error
    end
  end
end
