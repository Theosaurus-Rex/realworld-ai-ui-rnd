defmodule Realworld.Articles.ArticleTag do
  @moduledoc """
  The join resource between Article and Tag
  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: Realworld.Articles

  alias Realworld.Articles.Article
  alias Realworld.Articles.Tag

  postgres do
    table "article_tags"
    repo Realworld.Repo

    references do
      reference :article, on_delete: :delete
      reference :tag, on_delete: :delete
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  attributes do
    # No uuid_primary_key since we're using composite primary keys
  end

  relationships do
    belongs_to :article, Article, primary_key?: true, allow_nil?: false
    belongs_to :tag, Tag, primary_key?: true, allow_nil?: false
  end
end
