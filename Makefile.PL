use inc::Module::Install;

name 'comicser';
version '0.01';
author 'Alexey Surikov';
license 'perl';

requires 'URI';
requires 'UUID::Tiny';
requires 'DBIx::Class';
requires 'Image::Size';
requires 'Archive::Any';
requires 'Image::Resize';
requires 'Validate::Tiny';
requires 'Mojolicious::Lite';
requires 'HTTP::BrowserDetect';
requires 'File::Type::WebImages';
requires 'Class::Method::Modifiers';
requires 'Mojolicious::Plugin::ValidateTiny';

#auto_install;

WriteAll;
