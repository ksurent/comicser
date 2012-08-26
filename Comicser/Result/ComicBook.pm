package Comicser::Result::ComicBook;

use utf8;
use v5.14;
use parent 'DBIx::Class::Core';

use Class::Method::Modifiers;

__PACKAGE__->table('comic_book');

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
    painter => {
        data_type     => 'varchar',
        default_value => 'Unknown',
        is_nullable   => 0,
        size          => 255,
    },
    publisher => {
        data_type     => 'varchar',
        default_value => 'Unknown',
        is_nullable   => 0,
        size          => 255,
    },
    thumbnail_id => {
        data_type      => 'integer',
        extra          => {unsigned => 1},
        is_nullable    => 0,
    },
    complete => {
        data_type     => 'tinyint',
        default_value => 0,
        extra         => {unsigned => 1},
        is_nullable   => 0,
        size          => 1,
    },
    created => {
        data_type                 => 'datetime',
        datetime_undef_if_invalid => 1,
        default_value             => '1970-01-01 01:00:01',
        is_nullable               => 0,
    },
    last_update => {
        data_type                 => 'timestamp',
        datetime_undef_if_invalid => 1,
        default_value             => \'current_timestamp',
        is_nullable               => 0,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(
    chapters => 'Comicser::Result::Chapter',
    'comic_book_id',
    {
        order_by => {-desc => 'ordinal'},
    },
);

__PACKAGE__->has_one(
    thumbnail => 'Comicser::Result::Image',
    {
        'foreign.id' => 'self.thumbnail_id',
    },
);

sub new {
    my($self, $args) = @_;

    $args->{created} //= \'now()';

    $self->next::method($args);
}

sub delete {
    my $self = shift;

    $self->chapters->delete_all;
    $self->thumbnail->delete;

    $self->next::method;
}

sub to_hash {
    my $self = shift;
    
    +{$self->get_columns};
}

1;
