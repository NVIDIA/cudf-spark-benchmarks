
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
    WHERE ca_city IS NOT NULL
    AND ca_state IS NOT NULL
    AND ca_zip IS NOT NULL
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_sales_price) AS avg_sales,
        SUM(ws_quantity) AS total_quantity
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ai.full_address,
        sd.total_orders,
        sd.total_sales,
        sd.avg_sales,
        sd.total_quantity
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressInfo ai ON c.c_current_addr_sk = ai.ca_address_sk
    LEFT JOIN SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
),
AggregatedInfo AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.full_address,
        COALESCE(ci.total_orders, 0) AS total_orders,
        COALESCE(ci.total_sales, 0) AS total_sales,
        COALESCE(ci.avg_sales, 0) AS avg_sales,
        COALESCE(ci.total_quantity, 0) AS total_quantity,
        ROW_NUMBER() OVER (ORDER BY COALESCE(ci.total_sales, 0) DESC) AS rank
    FROM CustomerInfo ci
)
SELECT 
    a.c_customer_sk,
    a.c_first_name,
    a.c_last_name,
    a.cd_gender,
    a.cd_marital_status,
    a.cd_education_status,
    a.full_address,
    a.total_orders,
    a.total_sales,
    a.avg_sales,
    a.total_quantity,
    a.rank
FROM AggregatedInfo a
WHERE a.rank <= 100
ORDER BY a.rank;
