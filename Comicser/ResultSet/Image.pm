package Comicser::ResultSet::Image;

use utf8;
use v5.14;
use parent 'DBIx::Class::ResultSet';

use File::Temp            ();
use File::Copy            ();
use File::Spec            ();
use UUID::Tiny            ();
use Image::Size           ();
use Scalar::Util          ();
use Image::Resize         ();
use File::Type::WebImages ();

$Image::Size::NO_CACHE = 1;

sub create_from_asset {
    my($self, $args) = @_;

    my $asset = delete $args->{asset};

    my($fh, $file) = File::Temp::tempfile('comicser' . File::Temp::TEMPXXX, CLEANUP => 0, TMPDIR => 1);
    binmode $fh;
    print $fh $asset->get_chunk(0);
    close $fh;

    $args->{file} = $file;

    $self->create_from_file($args);
}

sub create_from_file {
    my($self, $args) = @_;

    my $file = delete $args->{file};

    my $mime_type = File::Type::WebImages::mime_type($file)
        or die 'Unsupported file type';

    my $ext;
    given($mime_type) {
        when(/jpeg/) { $ext = 'jpg' }
        when(/png/)  { $ext = 'png' }
        when(/gif/)  { $ext = 'gif' }
        default      { die 'Unsupported file type' }
    }

    my $new_name = join '.', UUID::Tiny::create_UUID_as_string(UUID::Tiny::UUID_V4), $ext;
    my $new_file = File::Spec->catfile(delete $args->{path}, $new_name);

    File::Copy::move($file, $new_file);

    my($width, $height) = Image::Size::imgsize($new_file);
    my $max_width  = delete $args->{max_width};
    my $max_height = delete($args->{max_height}) // int($height - $height / ($width / ($width - 940)));

    if(
        defined $max_width
        and defined $max_height
        and (
            $width > $max_width
            or $height > $max_height
        )
    )
    {
        my $resizer = Image::Resize->new($new_file);
        my $resized = $resizer->resize($max_width, $max_height);

        open my $fh, '>', $new_file or die "$new_file: $!";
        binmode $fh;
        given($mime_type) {
            when(/jpeg/) { print $fh $resized->jpeg }
            when(/png/)  { print $fh $resized->png  }
            when(/gif/)  { print $fh $resized->gif  }
        }
        close $fh;

        ($width, $height) = Image::Size::imgsize($new_file);
    }

    # TODO optimize image

    $self->create({
        file   => $new_name,
        width  => $width,
        height => $height,
    });
}

1;
