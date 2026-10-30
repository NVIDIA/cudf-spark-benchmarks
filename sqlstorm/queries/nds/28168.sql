
WITH AddressDetails AS (
    SELECT 
        ca_city, 
        ca_state, 
        COUNT(*) AS address_count,
        CONCAT(ca_city, ', ', ca_state) AS full_address,
        TRIM(UPPER(ca_street_name)) AS normalized_street_name
    FROM customer_address
    WHERE ca_country = 'USA'
    GROUP BY ca_city, ca_state, ca_street_name
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_education_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        (ws.ws_quantity * ws.ws_sales_price) AS total_sales
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk >= 20230101
),
DailySalesSummary AS (
    SELECT 
        d.d_date AS sale_date, 
        SUM(sd.total_sales) AS daily_total_sales,
        COUNT(DISTINCT sd.ws_item_sk) AS unique_items_sold
    FROM SalesData sd
    JOIN date_dim d ON sd.ws_ship_date_sk = d.d_date_sk
    GROUP BY d.d_date
)
SELECT 
    ad.full_address, 
    ad.address_count, 
    ci.full_name, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ci.cd_education_status, 
    ds.sale_date, 
    ds.daily_total_sales,
    ds.unique_items_sold
FROM AddressDetails ad
JOIN CustomerInfo ci ON ci.c_customer_sk IN (
    SELECT sr_customer_sk FROM store_returns 
    WHERE sr_returned_date_sk = (
        SELECT MAX(sr_returned_date_sk) FROM store_returns)
)
JOIN DailySalesSummary ds ON ds.sale_date > DATE '2023-01-01'
ORDER BY ad.address_count DESC, ds.daily_total_sales DESC
LIMIT 100;
