package Comicser::ResultSet::Page;

use utf8;
use v5.14;
use parent 'DBIx::Class::ResultSet';

use File::Path            ();
use File::Temp            ();
use Archive::Any          ();
use File::Type::WebImages ();

sub by_id {
    my($self, $id) = @_;

    $self->find($id);
}

sub by_ordinals {
    my($self, $comic_book_id, $chapter_ordinal, $page_ordinal) = @_;

    $self->search(
        {
            'chapter.comic_book_id' => $comic_book_id,
            'chapter.ordinal'       => $chapter_ordinal,
            'me.ordinal'            => $page_ordinal,
        },
        {
            prefetch => [qw(chapter image)],
        },
    )->single;
}

sub update_with_image {
    my($self, $args) = @_;

    my $page = $self->find(delete $args->{id});

    my $old_image = $page->image;
    my $new_image = $self->related_resultset('image')->create_from_asset({
        asset      => delete $args->{asset},
        path       => delete $args->{path},
        max_width  => delete $args->{max_width},
        max_height => delete $args->{max_height},
    });

    $page->image_id($new_image->id);
    $page->update;

    $old_image->delete;

    $page;
}

sub create_with_image {
    my($self, $args) = @_;

    my $method;
    if(exists $args->{asset})   { $method = 'create_from_asset' }
    elsif(exists $args->{file}) { $method = 'create_from_file'  }
    else { die 'Neither "file" nor "asset" was specified' }

    my $image = $self->related_resultset('image')->$method({
        $method eq 'create_from_asset'
            ? (asset => delete $args->{asset})
            : (file  => delete $args->{file}),
        path       => delete $args->{path},
        max_width  => delete $args->{max_width},
        max_height => delete $args->{max_height},
    });

    $image->create_related(
        'page',
        {
            chapter_id => delete $args->{chapter_id},
        },
    );
}

sub create_from_archive {
    my($self, $args) = @_;

    my $asset      = delete $args->{archive};
    my $chapter_id = delete $args->{chapter_id};
    my $path       = delete $args->{path};
    my $max_width  = delete $args->{max_width};
    my $max_height = delete $args->{max_height};

    my $template = 'comicser' . File::Temp::TEMPXXX;

    my(undef, $temp_file) = File::Temp::tempfile($template, OPEN => 0, TMPDIR => 1);
    $asset->move_to($temp_file);

    my $archive  = Archive::Any->new($temp_file);
    my $temp_dir = File::Temp::tempdir($template, CLEANUP => 0, TMPDIR => 1);
    $archive->extract($temp_dir);

    my @files = sort { $a cmp $b }
                grep defined File::Type::WebImages::mime_type($_),
                map File::Spec->catfile($temp_dir, $_),
                $archive->files;

    my @pages;
    for(@files) {
        push @pages, $self->create_with_image({
            file       => $_,
            path       => $path,
            chapter_id => $chapter_id,
            max_width  => $max_width,
            max_height => $max_height,
        });
    }

    unlink $temp_file;
    File::Path::remove_tree($temp_dir);

    wantarray ? @pages : \@pages;
}

1;
