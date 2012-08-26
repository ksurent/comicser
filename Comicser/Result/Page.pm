package Comicser::Result::Page;

use utf8;
use v5.14;
use parent 'DBIx::Class::Core';

use Class::Method::Modifiers;

__PACKAGE__->table('page');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        extra             => {unsigned => 1},
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    ordinal => {
        data_type     => 'integer',
        extra         => {unsigned => 1},
        default_value => 0,
        is_nullable   => 0,
    },
    chapter_id => {
        data_type      => 'integer',
        extra          => {unsigned => 1},
        is_nullable    => 0,
    },
    image_id => {
        data_type      => 'integer',
        extra          => {unsigned => 1},
        is_nullable    => 0,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
    chapter => 'Comicser::Result::Chapter',
    'chapter_id',
);

__PACKAGE__->has_one(
    image => 'Comicser::Result::Image',
    {
        'foreign.id' => 'self.image_id',
    },
);

__PACKAGE__->load_components('Ordered');
__PACKAGE__->position_column('ordinal');
__PACKAGE__->grouping_column('chapter_id');

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

    $self->image->delete;

    $self->next::method;
}

sub next_page {
    my $self = shift;

    my $next;

    my $next_page = $self->next_sibling;
    unless($next_page) {
        my $next_chapter = $self->chapter->next_sibling;
        if($next_chapter) {
            $next->{chapter} = $next_chapter->ordinal;
            $next->{page}    = 1;
        }
        else {
            $next->{chapter} = $next->{page} = 0;
        }
    }
    else {
        $next->{chapter} = $self->chapter->ordinal;
        $next->{page}    = $next_page->ordinal;
    }

    if($next->{page}) {
        $next_page = $self->result_source->resultset->by_ordinals(
            $self->chapter->comic_book->id,
            $next->{chapter},
            $next->{page},
        );
        $next->{image} = $next_page->image->url;
    }

    $next;
}

sub previous_page {
    my $self = shift;

    my $prev;

    my $prev_page = $self->previous_sibling;
    unless($prev_page) {
        my $prev_chapter = $self->chapter->previous_sibling;
        if($prev_chapter) {
            $prev->{chapter} = $prev_chapter->ordinal;
            $prev->{page}    = $prev_chapter->pages->first->ordinal;
        }
        else {
            $prev->{chapter} = $prev->{page} = 0;
        }
    }
    else {
        $prev->{chapter} = $self->chapter->ordinal;
        $prev->{page}    = $prev_page->ordinal;
    }

    $prev;
}

sub to_hash {
    my $self = shift; 

    +{$self->get_columns, description => $self->description};
}

sub description {
    my $self = shift;

    sprintf '%s, chapter %i, page %i', $self->chapter->comic_book->title,
                                       $self->chapter->ordinal,
                                       $self->ordinal;
}

sub _update_comic_book_time {
    my $self = shift;

    my $comic_book = $self->chapter->comic_book;
    $comic_book->last_update(\'now()');
    $comic_book->update;
}

1;
