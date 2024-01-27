--Find your dream book
create extension postgis;
set search_path to public;

--Table school

create table school(
id serial,
name varchar(255),
geom geometry(POINT,4326),
primary key (id)
);

insert into school(name,geom)
select name, ST_centroid(ST_transform(way,4326)) 
from planet_osm_polygon 
where amenity = 'school';

insert into school(name,geom)
select name, ST_transform(way,4326)
from planet_osm_point
where amenity = 'school';

--Table class
create table class(
id serial,
name varchar(10) NOT NULL,
school_id int,
primary key (id),
foreign key (school_id) references school(id)
);


--Table student 
create table student(
id serial,
class_id int,
name varchar(50),
surname varchar(50),
home_geom geometry(POINT,4326),
primary key (id),
foreign key (class_id) references class(id)
);


--Table library
create table library(
id serial,
name varchar(255),
geom geometry(POINT,4326),
primary key (id)
);

insert into library(name,geom)
select name, ST_centroid(ST_transform(way,4326)) 
from planet_osm_polygon 
where amenity = 'library';

insert into library(name,geom)
select name, ST_transform(way,4326)
from planet_osm_point
where amenity = 'library';


--Table book_store
create table book_store(
id serial,
name varchar(255),
geom geometry(POINT,4326),
primary key (id)
);

insert into book_store(name,geom)
select name, ST_centroid(ST_transform(way,4326)) 
from planet_osm_polygon 
where shop = 'books';

insert into book_store(name,geom)
select name, ST_transform(way,4326)
from planet_osm_point
where shop = 'books';



--Table author
create table author(
id serial,
name varchar(50),
surname varchar(50),
primary key (id)
);

--Table book
create domain language_dm 
as varchar(10) 
default 'unknown'
check (value in('unknown','sk','en'));

alter table book
add language language_dm;

drop table book;
create table book(
id serial,
title varchar(255),
author_id int,
language language_dm,
primary key (id),
foreign key (author_id) references author(id)
);

--Table district
create table district as(
select id,nm3, geom 
from district2
);

alter table district
add primary key (id);

--Conection tables 
create table library_book(
id serial,
library_id int,
book_id int,
primary key (id),
foreign key (library_id) references library(id),
foreign key (book_id) references book(id)
);

create table book_store_book(
id serial,
book_store_id int,
book_id int,
primary key (id),
foreign key (book_store_id) references book_store(id),
foreign key (book_id) references book(id)
);

--Add values into tables
--Table class
insert into class(school_id,name)
values
(1,'5.A'),
(1,'9.A'),
(2,'1.A'),
(2,'4.A'),
(3,'7.A');

--Table student
insert into student(class_id,name,surname,home_geom)
values
(1,'Miroslava','Novak',ST_GeomFromText('POINT(17.09976 48.14910)')), 
(1,'Martin','Hrivnak',ST_GeomFromText('POINT(17.15045 48.15725)')), 
(2,'Eva','Kovacova',ST_GeomFromText('POINT(17.03582 48.18880)')), 
(2,'Juraj','Mikula',ST_GeomFromText('POINT(20.21712 49.13912 )')),
(3,'Zuzana','Kovac',ST_GeomFromText('POINT(21.23501 48.99800 )')),
(3,'Lukas','Varga',ST_GeomFromText('POINT(18.78043 49.43734)')),
(4,'Katarina','Kolarova',ST_GeomFromText('POINT(18.86123 48.86298)')),
(4,'Michal','Dvorak',ST_GeomFromText('POINT(22.15608 48.99165 )')),
(5,'Nina','Barta',ST_GeomFromText('POINT(19.14050 48.73755 )')),
(5,'Matej','Horvath',ST_GeomFromText('POINT(19.61720 49.08056 )'));

--Table author
insert into author(name,surname)
values
('Sarah','Turner'),
('James','Montgomery'),
('Isabella','Cruz'),
('Robert','Greene'),
('Eleanor','Harper');


--Table book
insert into book(author_id,title,language)
values
(1,'Whispers in the Wind','en'),
(1,'Ephemeral Echoes','sk'),
(2,'Echoes of Eternity','en'),
(2,'The Last Alchemist','en'),
(3,'Sirens of the Sea','sk'),
(3,'Labyrinth of Lies','unknown'),
(4,'The Quantum Paradox','en'),
(4,'Art of Illusion','sk'),
(5,'Lost Legends','unknown'),
(5,'Shadows of Serenity','en');

--Conection table
insert into book_store_book(book_store_id,book_id)
values
(42,7),
(19,3),
(73,9),
(64,5),
(95,8),
(37,2),
(50,10),
(12,1),
(88,6),
(5,4),
(29,7),
(68,2),
(21,9),
(35,1),
(96,5),
(7,8),
(48,3),
(10,6),
(81,9),
(53,4);

insert into library_book(library_id,book_id)
values
(56,3),
(18,6),
(72,8),
(39,2),
(91,9),
(27,7),
(64,1),
(13,4),
(85,5),
(47,10),
(31,3),
(77,6),
(22,8),
(58,1),
(43,5),
(95,7),
(15,4),
(69,9),
(54,2),
(36,10);



--Views
create view students_in_class as (
select student.name, student.surname, class.name as class
from student 
inner join class on student.class_id = class.id);

create view library_in_BA as(
select library.name, district.nm3 as district
from library, district
where ST_intersects(library.geom,district.geom) and district.nm3 like 'Bratislava%'
);

--Users
create user alice with password 'alice'; 
grant select,update on all tables in schema public to alice;

create user bob with password 'bob';
grant select on all tables in schema public to bob;

--Queries in DB

--Q1 number of librarys in every district
select district.nm3 as name, count(library.id) as number_of_librarys
from district,library
where ST_intersects(library.geom,district.geom)
group by district.nm3
order by number_of_librarys desc;

--Q2 number of students in Bratislava city
select count(student.id) as number_of_students_in_Kosice
from student, district
where ST_intersects(student.home_geom,district.geom) and district.nm3 like 'Bratislava%';

--Q3 authors with book titles
select author.name, author.surname, book.title
from author
inner join book on author.id = book.author_id;

--Q4 closest library from home of student with id 1
select student.name, student.surname, ST_distance(ST_transform(student.home_geom,5514),
ST_transform(library.geom,5514)) as distance_to_library, library.name as library
from library, student
where student.id = 1 
order by distance_to_library
limit 1;

--Q5 number of schools in Poprad district
select count(school.id) as number_of_schools_in_Poprad
from school, district
where ST_intersects(school.geom,district.geom) and district.nm3 = 'Poprad';

--Q6 in how many bookstores have auther some book
select author.id as author_id,author.name as author_name,
count(distinct book_store_book.book_store_id) as bookstores_count
from author
join book on author.id = book.author_id
join book_store_book on book.id = book_store_book.book_id
group by author.id, author.name
order by bookstores_count desc;

--Q7 nearest school from home for every student
select student.id as student_id, student.name as student_name, student.surname as student_surname, 
class.name as class_name, school.name as school_name
from student
join class on student.class_id = class.id
join school on class.school_id = school.id
join district on ST_Within(student.home_geom, district.geom);

--Q8 in which book stores have books from Sarah Turner
select book.title, book_store.name
from book_store
join book_store_book ON book_store_book.book_store_id = book_store.id
join book on book.id = book_store_book.book_id
where book.author_id = (select id from author where name = 'Sarah' and surname = 'Turner');







