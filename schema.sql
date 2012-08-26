drop table if exists comic_book;
create table comic_book(
    id int unsigned not null auto_increment primary key,
    thumbnail_id int unsigned not null,
    title varchar(255) character set utf8 not null,
    painter varchar(255) character set utf8 not null default 'Unknown',
    publisher varchar(255) character set utf8 not null default 'Unknown',
    complete tinyint(1) unsigned not null default 0,
    created datetime not null default '1970-01-01 01:00:01',
    last_update timestamp not null default current_timestamp on update current_timestamp
) engine=innodb;

drop table if exists chapter;
create table chapter(
    id int unsigned not null auto_increment primary key,
    comic_book_id int unsigned not null,
    ordinal int unsigned not null default 0,
    title varchar(255) character set utf8 not null
) engine=innodb;

drop table if exists page;
create table page(
    id int unsigned not null auto_increment primary key,
    chapter_id int unsigned not null,
    image_id int unsigned not null,
    ordinal int unsigned not null default 0
) engine=innodb;

drop table if exists image;
create table image(
    id int unsigned not null auto_increment primary key,
    file varchar(255) not null,
    width smallint unsigned not null,
    height smallint unsigned not null
) engine=innodb;
