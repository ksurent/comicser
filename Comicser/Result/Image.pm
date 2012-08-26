package Comicser::Result::Image;

use utf8;
use v5.14;
use parent 'DBIx::Class::Core';

use URI;
use File::Spec;
use Class::Method::Modifiers;

__PACKAGE__->table('image');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        extra             => {unsigned => 1},
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    file => {
        data_type   => 'varchar',
        is_nullable => 0,
        size        => 255,
    },
    width => {
        data_type   => 'smallint',
        extra       => {unsigned => 1},
        is_nullable => 0,
    },
    height => {
        data_type   => 'smallint',
        extra       => {unsigned => 1},
        is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
    comic_book => 'Comicser::Result::ComicBook',
    {
        'foreign.thumbnail_id' => 'self.id',
    },
);

__PACKAGE__->belongs_to(
    page => 'Comicser::Result::Page',
    {
        'foreign.image_id' => 'self.id',
    },
);

sub delete {
    my $self = shift;

    my $rel_file = File::Spec->catfile(qw(public images), $self->file);
    unlink File::Spec->rel2abs($rel_file);

    $self->next::method;
}

sub url {
    my $self = shift;

    my $url = URI->new('/', 'http');
    $url->path('/images/' . $self->file);

    $url;
}

sub to_hash {
    my $self = shift;
    
    +{$self->get_columns, url => $self->url};
}

1;
