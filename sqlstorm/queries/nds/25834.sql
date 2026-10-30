
WITH AddressCTE AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM customer_address
),
CustomerCTE AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        a.full_address
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressCTE a ON c.c_current_addr_sk = a.ca_address_sk
),
SalesCTE AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerSalesCTE AS (
    SELECT 
        c.*, 
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(s.total_orders, 0) AS total_orders
    FROM CustomerCTE c
    LEFT JOIN SalesCTE s ON c.c_customer_sk = s.ws_bill_customer_sk
)
SELECT 
    cs.full_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_sales,
    cs.total_orders,
    ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
FROM CustomerSalesCTE cs
WHERE cs.cd_purchase_estimate > 1000
ORDER BY sales_rank
LIMIT 10;
