package Comicser::Result::Chapter;

use utf8;
use v5.14;
use parent 'DBIx::Class::Core';

use Class::Method::Modifiers;

__PACKAGE__->table('chapter');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        extra             => {unsigned => 1},
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    title => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 255,
    },
    ordinal => {
        data_type     => 'integer',
        extra         => {unsigned => 1},
        default_value => 0,
        is_nullable   => 0,
    },
    comic_book_id => {
        data_type      => 'integer',
        extra          => {unsigned => 1},
        is_nullable    => 0,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
    comic_book => 'Comicser::Result::ComicBook',
    'comic_book_id',
);

__PACKAGE__->has_many(
    pages => 'Comicser::Result::Page',
    'chapter_id',
    {
        order_by => {-desc => 'ordinal'},
    },
);

__PACKAGE__->load_components('Ordered');
__PACKAGE__->position_column('ordinal');
__PACKAGE__->grouping_column('comic_book_id');

after insert => sub {
    my $self = shift;

    $self->_update_comic_book_time;
};

after update => sub {
    my $self = shift;

    $self->_update_comic_book_time;
};

sub delete {
    my $self = shift;

    $self->pages->delete_all;

    $self->next::method;
}

sub to_hash {
    my $self = shift;

    +{$self->get_columns};
}

sub _update_comic_book_time {
    my $self = shift;

    my $comic_book = $self->comic_book;
    $comic_book->last_update(\'now()');
    $comic_book->update;
}

1;
