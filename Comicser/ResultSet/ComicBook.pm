package Comicser::ResultSet::ComicBook;

use utf8;
use v5.14;
use parent 'DBIx::Class::ResultSet';

sub by_id {
    my($self, $id) = @_;

    $self->find($id);
}

sub list {
    my($self, $sort) = @_;

    $sort //= 'created';
    $sort   = 'created' if $sort ne 'created' and $sort ne 'last_update';

    $self->search(
        {},
        {
            prefetch => 'thumbnail',
            order_by => {-desc => $sort},
        },
    )->all;
}

sub list_with_pages {
    my($self, $sort) = @_;

    $sort //= 'created';
    $sort   = 'created' if $sort ne 'created' and $sort ne 'last_update';

    my @comics = $self->search(
        {},
        {
            prefetch => [qw(thumbnail chapters)],
            order_by => {-desc => $sort},
        },
    )->all;
    @comics = grep {
        my $ch = $_->chapters;
        $ch->count and grep $_->pages->count, $ch->all
    } @comics;

    @comics;
}

sub create_with_thumbnail {
    my($self, $args) = @_;

    my $thumbnail = $self->related_resultset('thumbnail')->create_from_asset({
        asset      => delete $args->{asset},
        path       => delete $args->{path},
        max_width  => delete $args->{max_width},
        max_height => delete $args->{max_height},
    });

    $thumbnail->create_related(
        'comic_book',
        {
            title     => delete $args->{title},
            painter   => delete $args->{painter},
            publisher => delete $args->{publisher},
        },
    );
}

sub update_with_thumbnail {
    my($self, $args) = @_;

    my $comic_book = $self->find(delete $args->{id});

    my $old_thumbnail = $comic_book->thumbnail;
    my $new_thumbnail = $self->related_resultset('thumbnail')->create_from_asset({
        asset      => delete $args->{asset},
        path       => delete $args->{path},
        max_width  => delete $args->{max_width},
        max_height => delete $args->{max_height},
    });

    $comic_book->title(delete $args->{title});
    $comic_book->painter(delete $args->{painter});
    $comic_book->publisher(delete $args->{publisher});
    $comic_book->thumbnail_id($new_thumbnail->id);
    $comic_book->update;

    $old_thumbnail->delete;

    $comic_book;
}

1;
