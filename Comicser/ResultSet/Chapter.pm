package Comicser::ResultSet::Chapter;

use utf8;
use v5.14;
use parent 'DBIx::Class::ResultSet';

sub by_id {
    my($self, $id) = @_;

    $self->find($id);
}

1;
