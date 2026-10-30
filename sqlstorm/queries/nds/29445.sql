
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        CASE 
            WHEN ca_city IS NOT NULL THEN CONCAT(ca_city, ', ')
            ELSE ''
        END AS city_details,
        CASE 
            WHEN ca_state IS NOT NULL THEN CONCAT(ca_state, ' ')
            ELSE ''
        END AS state_details,
        CASE 
            WHEN ca_zip IS NOT NULL THEN CONCAT(ca_zip, ', ')
            ELSE ''
        END AS zip_details,
        ca_country
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ad.full_address,
        ad.city_details,
        ad.state_details,
        ad.zip_details,
        ad.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
DateDetails AS (
    SELECT 
        d.d_date_sk, 
        d.d_date,
        d.d_day_name,
        d.d_month_seq,
        d.d_year
    FROM date_dim d
    WHERE d.d_date BETWEEN '2022-01-01' AND '2022-12-31'
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    dd.d_date,
    dd.d_day_name,
    dd.d_month_seq,
    dd.d_year,
    sd.total_quantity_sold,
    sd.total_net_profit,
    CONCAT(cd.city_details, cd.state_details, cd.zip_details, cd.ca_country) AS full_location
FROM CustomerDetails cd
JOIN DateDetails dd ON dd.d_date_sk IN (
    SELECT DISTINCT ws_sold_date_sk FROM web_sales
)
LEFT JOIN SalesData sd ON sd.ws_sold_date_sk = dd.d_date_sk
ORDER BY dd.d_date, cd.full_name;
