-- Define roles for users
create type role as enum ('ROLE_ADMIN', 'ROLE_DRIVER', 'ROLE_CLIENT');

-- Create sequence for user id
create sequence if not exists user_id_seq;

-- Define the user table
create table if not exists "user"(
    user_id int generated by default as identity primary key,  -- User ID
    name varchar(100) not null,                               -- User name
    email varchar(100) not null unique,                       -- User email
    password varchar(100) not null,                           -- User password
    banned bool not null default false,                       -- Ban status
    role role not null default 'ROLE_CLIENT'::role            -- User role
);

-- Define the client table
create table if not exists "client"(
    client_id int generated by default as identity primary key references "user"(user_id) on delete cascade,  -- Client ID
    phone_number varchar(13) not null unique,                -- Client phone number
    rating double precision not null default 0,              -- Client rating
    has_active_order bool not null default false,            -- Whether client has active order
    bonus_amount float not null default 0,                   -- Bonus amount for client
    number_of_ratings int not null default 0,                -- Number of ratings
    total_ratings int not null default 0                     -- Total ratings score
);

-- Define car classes
create type car_class as enum ('ECONOMY', 'BUSINESS');

-- Define vehicle types
create type vehicle_type as enum ('SEDAN', 'HATCHBACK', 'MINIVAN', 'MINIBUS');

-- Create sequence for user id
create sequence if not exists car_id_seq;

-- Define the car table
create table if not exists "car"(
    car_id int generated by default as identity primary key,  -- Car ID
    license_plate varchar(8) not null unique,                 -- License plate
    model varchar(100) not null,                              -- Car model
    color varchar(20) not null,                               -- Car color
    car_class car_class not null,                             -- Car class
    vehicle_type vehicle_type not null                        -- Vehicle type
);

-- Define the driver table
create table if not exists "driver"(
    driver_id int generated by default as identity primary key references "user"(user_id) on delete cascade, -- Driver ID
    license_number varchar(10) not null unique,               -- License number
    rating double precision not null default 0,               -- Driver rating
    phone_number varchar(13) not null unique,                 -- Phone number
    busy bool not null default false,                         -- Whether driver is busy
    car_id int unique references "car"(car_id) on delete set null,  -- Car ID
    number_of_ratings int not null default 0,                 -- Number of ratings
    total_ratings int not null default 0                      -- Total ratings score
);

-- Define payment types
create type payment_type as enum ('CASH', 'CARD');

-- Define order statuses
create type order_status as enum ('NOT_ACCEPTED', 'ACCEPTED', 'CANCELLED', 'WAITING_FOR_CLIENT', 'IN_PROCESS', 'COMPLETED', 'RATED_BY_CLIENT', 'RATED_BY_DRIVER', 'RATED_BY_ALL');

-- Define the order table
create table if not exists "order"(
    order_id int generated by default as identity primary key,  -- Order ID
    client_id int references "client"(client_id) on delete set null, -- Client ID
    driver_id int references "driver"(driver_id) on delete set null, -- Driver ID
    booking_datetime timestamp not null,                        -- Booking datetime
    order_creation_datetime timestamp not null,                 -- Order creation datetime
    pickup_address varchar(400) not null,                       -- Pickup address
    destination_address varchar(400) not null,                  -- Destination address
    journey_distance decimal(10,2) not null,                    -- Journey distance
    passenger_name varchar(100),                                -- Passenger name
    passenger_phone_number varchar(13),                         -- Passenger phone number
    booking_notes varchar(150),                                 -- Booking notes
    payment_type payment_type not null,                         -- Payment type
    pay_with_bonuses bool not null default false,               -- Pay with bonuses
    car_class car_class not null,                               -- Car class
    vehicle_type vehicle_type not null,                         -- Vehicle type
    price decimal(10,2) not null,                               -- Price
    order_status order_status not null default 'NOT_ACCEPTED'::order_status,  -- Order status
    hash varchar(12) not null
);

-- Trigger for hashing order_id
CREATE OR REPLACE FUNCTION create_hash() RETURNS TRIGGER AS $$
BEGIN
    NEW.hash := substring(md5(NEW.order_id::text) from 1 for 12);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insert_hash_trigger
    BEFORE INSERT ON "order"
    FOR EACH ROW
EXECUTE FUNCTION create_hash();

-- Trigger for setting order_creation_datetime
CREATE OR REPLACE FUNCTION set_order_creation_datetime()
    RETURNS TRIGGER AS
$$
BEGIN
    NEW.order_creation_datetime = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER set_order_creation_datetime_trigger
    BEFORE INSERT ON "order"
    FOR EACH ROW
EXECUTE FUNCTION set_order_creation_datetime();



-- Filling data, clients and drivers must be created manually due to password encoding
INSERT INTO "order"(
    client_id, driver_id, booking_datetime, order_creation_datetime, pickup_address,
    destination_address, journey_distance, passenger_name, passenger_phone_number, booking_notes,
    payment_type, pay_with_bonuses, car_class, vehicle_type, price, order_status, hash
) VALUES
      -- Cancelled orders
      (1, NULL, '2023-05-30 10:55:00.000000', '2023-05-28 10:55:26.096341', '������ �������, Kharkiv, Kharkiv Oblast, Ukraine',
       '���������� ������������ ��������, Kyrpychova Street, Kharkiv, Kharkiv Oblast, Ukraine', 7437.00, '', '', '', 'CASH', false, 'BUSINESS', 'HATCHBACK', 223.11, 'CANCELLED', 'eccbc87e4b5c'),
      (1, NULL, '2023-05-28 11:00:00.000000', '2023-05-28 11:00:49.887043', '������ �������, Kharkiv, Kharkiv Oblast, Ukraine',
       '���������� ������������ ��������, Kyrpychova Street, Kharkiv, Kharkiv Oblast, Ukraine', 7437.00, '', '', '', 'CARD', false, 'BUSINESS', 'HATCHBACK', 223.11, 'CANCELLED', 'a87ff679a2f3'),
      (5, NULL, '2023-05-28 11:04:00.000000', '2023-05-28 11:04:48.649585', '������ �������, Kharkiv, Kharkiv Oblast, Ukraine',
       '���������� ������������ ��������, Kyrpychova Street, Kharkiv, Kharkiv Oblast, Ukraine', 7437.00, '', '', '', 'CARD', false, 'BUSINESS', 'HATCHBACK', 223.11, 'CANCELLED', 'e4da3b7fbbce'),
      (6, NULL, '2023-05-28 11:05:00.000000', '2023-05-28 11:05:14.446987', '������ �������, Kharkiv, Kharkiv Oblast, Ukraine',
       '�����, Nauky Avenue, Kharkiv, Kharkiv Oblast, Ukraine', 9214.00, '', '', '', 'CARD', true, 'BUSINESS', 'HATCHBACK', 274.42, 'CANCELLED', '1679091c5a88'),
      (7, NULL, '2023-05-29 11:06:00.000000', '2023-05-28 11:06:54.362562', '������ �������, Kharkiv, Kharkiv Oblast, Ukraine',
       '���������� ������������ ��������, Kyrpychova Street, Kharkiv, Kharkiv Oblast, Ukraine', 7437.00, '', '', '', 'CARD', true, 'BUSINESS', 'HATCHBACK', 221.11, 'CANCELLED', '8f14e45fceea'),
      (12, NULL, '2023-05-28 11:07:00.000000', '2023-05-28 11:07:53.722514', '������ �������, Kharkiv, Kharkiv Oblast, Ukraine',
       '���������� ������������ ��������, Kyrpychova Street, Kharkiv, Kharkiv Oblast, Ukraine', 7437.00, '', '', '', 'CARD', false, 'BUSINESS', 'HATCHBACK', 223.11, 'CANCELLED', 'c9f0f895fb98'),
      (1, NULL, '2023-05-28 11:08:00.000000', '2023-05-28 11:08:25.671089', '������ �������, Kharkiv, Kharkiv Oblast, Ukraine',
       '���������� ������������ ��������, Kyrpychova Street, Kharkiv, Kharkiv Oblast, Ukraine', 7437.00, '', '', '', 'CARD', false, 'BUSINESS', 'HATCHBACK', 223.11, 'CANCELLED', '45c48cce2e2d'),
      (17, NULL, '2023-05-28 11:08:00.000000', '2023-05-28 11:08:44.087699', '���������� ������������ ��������, Kyrpychova Street, Kharkiv, Kharkiv Oblast, Ukraine',
       '������ �������, Kharkiv, Kharkiv Oblast, Ukraine', 7709.00, '', '', '', 'CARD', true, 'BUSINESS', 'HATCHBACK', 221.27, 'CANCELLED', 'd3d9446802a4'),
      (1, NULL, '2023-05-21 07:55:00.000000', '2023-05-20 06:55:26.096341', '������ �������, Kharkiv, Kharkiv Oblast, Ukraine',
       '���������� ������������ ��������, Kyrpychova Street, Kharkiv, Kharkiv Oblast, Ukraine', 7437.00, '', '', '', 'CASH', false, 'BUSINESS', 'HATCHBACK', 223.11, 'CANCELLED', '7ac41a8c3a99'),
      (1, NULL, '2023-05-25 06:00:00.000000', '2023-05-24 08:00:49.887043', '������ �������, Kharkiv, Kharkiv Oblast, Ukraine',
       '���������� ������������ ��������, Kyrpychova Street, Kharkiv, Kharkiv Oblast, Ukraine', 7437.00, '', '', '', 'CARD', false, 'BUSINESS', 'HATCHBACK', 223.11, 'CANCELLED', 'a28351d64c14'),
      (5, NULL, '2023-05-20 12:04:00.000000', '2023-05-19 09:04:48.649585', '������ �������, Kharkiv, Kharkiv Oblast, Ukraine',
       '���������� ������������ ��������, Kyrpychova Street, Kharkiv, Kharkiv Oblast, Ukraine', 7437.00, '', '', '', 'CARD', false, 'BUSINESS', 'HATCHBACK', 223.11, 'CANCELLED', 'bf628a7c7a72'),
      (6, NULL, '2023-05-20 14:05:00.000000', '2023-05-19 15:05:14.446987', '������ �������, Kharkiv, Kharkiv Oblast, Ukraine',
       '�����, Nauky Avenue, Kharkiv, Kharkiv Oblast, Ukraine', 9214.00, '', '', '', 'CARD', true, 'BUSINESS', 'HATCHBACK', 274.42, 'CANCELLED', 'c682ac23576c'),
      (13, NULL, '2023-05-22 10:06:00.000000', '2023-05-21 08:06:54.362562', '������ �������, Kharkiv, Kharkiv Oblast, Ukraine',
       '���������� ������������ ��������, Kyrpychova Street, Kharkiv, Kharkiv Oblast, Ukraine', 7437.00, '', '', '', 'CARD', true, 'BUSINESS', 'HATCHBACK', 221.11, 'CANCELLED', 'a1826a1aeebd'),
      (14, NULL, '2023-05-20 11:07:00.000000', '2023-05-19 10:07:53.722514', '������ �������, Kharkiv, Kharkiv Oblast, Ukraine',
       '���������� ������������ ��������, Kyrpychova Street, Kharkiv, Kharkiv Oblast, Ukraine', 7437.00, '', '', '', 'CARD', false, 'BUSINESS', 'HATCHBACK', 223.11, 'CANCELLED', 'f2e704ca7c9c'),
      (15, NULL, '2023-05-26 11:08:00.000000', '2023-05-25 11:08:25.671089', '������ �������, Kharkiv, Kharkiv Oblast, Ukraine',
       '���������� ������������ ��������, Kyrpychova Street, Kharkiv, Kharkiv Oblast, Ukraine', 7437.00, '', '', '', 'CARD', false, 'BUSINESS', 'HATCHBACK', 223.11, 'CANCELLED', '8a2a5cbfcd6e'),
      (16, NULL, '2023-05-27 12:08:00.000000', '2023-05-26 13:08:44.087699', '���������� ������������ ��������, Kyrpychova Street, Kharkiv, Kharkiv Oblast, Ukraine',
       '������ �������, Kharkiv, Kharkiv Oblast, Ukraine', 7709.00, '', '', '', 'CARD', true, 'BUSINESS', 'HATCHBACK', 221.27, 'CANCELLED', 'b56a548fa90b'),

      -- Finished orders
      (1, 2, '2023-05-29 12:36:00.000000', '2023-05-28 12:37:15.516732', '������ �������, Kharkiv, Kharkiv Oblast, Ukraine',
       '���������� ������������ ��������, Kyrpychova Street, Kharkiv, Kharkiv Oblast, Ukraine', 7437.00, '����', '0676002429', '�������', 'CARD', false, 'BUSINESS', 'HATCHBACK', 223.11, 'RATED_BY_ALL', '6512bd43d9ca'),
      (5, 11, '2023-05-29 13:34:00.000000', '2023-05-28 13:34:48.597665', '������ �������, Kharkiv, Kharkiv Oblast, Ukraine',
       '���������� ������������ ��������, Kyrpychova Street, Kharkiv, Kharkiv Oblast, Ukraine', 7437.00, '', '', '', 'CARD', false, 'ECONOMY', 'SEDAN', 223.11, 'RATED_BY_ALL', 'c20ad4d76fe9'),
      (6, 11, '2023-05-20 11:24:00.000000', '2023-05-19 14:34:48.597665', '������ �������, Kharkiv, Kharkiv Oblast, Ukraine',
       '���������� ������������ ��������, Kyrpychova Street, Kharkiv, Kharkiv Oblast, Ukraine', 7437.00, '', '', '', 'CASH', false, 'BUSINESS', 'HATCHBACK', 223.11, 'COMPLETED', '45c48cce2e2d'),
      (7, 2, '2023-05-24 13:47:00.000000', '2023-05-23 15:28:48.597665', '������ �������, Kharkiv, Kharkiv Oblast, Ukraine',
       '���������� ������������ ��������, Kyrpychova Street, Kharkiv, Kharkiv Oblast, Ukraine', 7437.00, '', '', '', 'CARD', false, 'BUSINESS', 'HATCHBACK', 223.11, 'RATED_BY_ALL', '1679091c5a88'),
      (17, 11, '2023-05-22 16:34:00.000000', '2023-05-21 16:59:48.597665', '������ �������, Kharkiv, Kharkiv Oblast, Ukraine',
       '���������� ������������ ��������, Kyrpychova Street, Kharkiv, Kharkiv Oblast, Ukraine', 7437.00, '', '', '', 'CASH', false, 'ECONOMY', 'SEDAN', 223.11, 'COMPLETED', '8f14e45fceea'),
      (13, 2, '2023-05-18 20:30:00.000000', '2023-05-17 18:34:48.597665', '������ �������, Kharkiv, Kharkiv Oblast, Ukraine',
       '���������� ������������ ��������, Kyrpychova Street, Kharkiv, Kharkiv Oblast, Ukraine', 7437.00, '', '', '', 'CARD', false, 'BUSINESS', 'HATCHBACK', 223.11, 'COMPLETED', 'd3d9446802a4'),
      (14, 2, '2023-05-25 10:36:00.000000', '2023-05-24 08:37:15.516732', '������ �������, Kharkiv, Kharkiv Oblast, Ukraine',
       '���������� ������������ ��������, Kyrpychova Street, Kharkiv, Kharkiv Oblast, Ukraine', 7437.00, '����', '0676002429', '�������', 'CARD', false, 'BUSINESS', 'HATCHBACK', 223.11, 'RATED_BY_ALL', '6dcd4ce23d88'),
      (15, 11, '2023-05-25 11:34:00.000000', '2023-05-24 09:34:48.597665', '������ �������, Kharkiv, Kharkiv Oblast, Ukraine',
       '���������� ������������ ��������, Kyrpychova Street, Kharkiv, Kharkiv Oblast, Ukraine', 7437.00, '', '', '', 'CARD', false, 'ECONOMY', 'SEDAN', 223.11, 'RATED_BY_ALL', 'aa68c7f7815c'),
      (16, 11, '2023-05-22 12:24:00.000000', '2023-05-21 10:34:48.597665', '������ �������, Kharkiv, Kharkiv Oblast, Ukraine',
       '���������� ������������ ��������, Kyrpychova Street, Kharkiv, Kharkiv Oblast, Ukraine', 7437.00, '', '', '', 'CASH', false, 'BUSINESS', 'HATCHBACK', 223.11, 'COMPLETED', 'c8f86411caea'),
      (7, 2, '2023-05-27 11:47:00.000000', '2023-05-26 09:28:48.597665', '������ �������, Kharkiv, Kharkiv Oblast, Ukraine',
       '���������� ������������ ��������, Kyrpychova Street, Kharkiv, Kharkiv Oblast, Ukraine', 7437.00, '', '', '', 'CARD', false, 'ECONOMY', 'SEDAN', 223.11, 'COMPLETED', 'b8c4e8b5c81a'),
      (7, 11, '2023-05-22 14:34:00.000000', '2023-05-21 12:59:48.597665', '������ �������, Kharkiv, Kharkiv Oblast, Ukraine',
       '���������� ������������ ��������, Kyrpychova Street, Kharkiv, Kharkiv Oblast, Ukraine', 7437.00, '', '', '', 'CASH', false, 'BUSINESS', 'HATCHBACK', 223.11, 'COMPLETED', 'db59b0df5f64'),
      (7, 2, '2023-05-20 18:30:00.000000', '2023-05-19 16:34:48.597665', '������ �������, Kharkiv, Kharkiv Oblast, Ukraine',
       '���������� ������������ ��������, Kyrpychova Street, Kharkiv, Kharkiv Oblast, Ukraine', 7437.00, '', '', '', 'CARD', false, 'BUSINESS', 'HATCHBACK', 223.11, 'COMPLETED', '73d34c464b8c');
