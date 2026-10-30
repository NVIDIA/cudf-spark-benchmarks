
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_country
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk, 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid) AS total_net_paid
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
DetailedSales AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        sd.total_quantity_sold,
        sd.total_net_paid,
        ad.full_address,
        cd.full_name
    FROM SalesData sd
    JOIN AddressDetails ad ON sd.ws_item_sk = ad.ca_address_sk
    JOIN CustomerDetails cd ON ad.ca_address_sk = cd.c_customer_sk
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY ws_sold_date_sk ORDER BY total_net_paid DESC) AS rank
    FROM DetailedSales
)
SELECT 
    ws_sold_date_sk AS date,
    full_address,
    full_name,
    total_quantity_sold,
    total_net_paid,
    rank
FROM RankedSales
WHERE rank <= 10
ORDER BY ws_sold_date_sk, rank;
