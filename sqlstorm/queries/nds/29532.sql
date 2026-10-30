
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        ca_street_number || ' ' || ca_street_name || ' ' || ca_street_type || 
        CASE 
            WHEN ca_suite_number IS NOT NULL THEN ' Suite ' || ca_suite_number 
            ELSE '' 
        END || 
        ', ' || ca_city || ', ' || ca_state || ' ' || ca_zip AS full_address,
        ca_country
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        c_first_name || ' ' || c_last_name AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        (SELECT COUNT(*) FROM household_demographics hd WHERE hd.hd_demo_sk = c_current_hdemo_sk) AS household_count,
        addr.full_address
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN AddressDetails addr ON c.c_current_addr_sk = addr.ca_address_sk
),
SalesAnalytics AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    cust.full_name,
    cust.cd_gender,
    cust.cd_marital_status,
    cust.cd_purchase_estimate,
    cust.cd_credit_rating,
    cust.household_count,
    cust.full_address,
    sales.total_sales,
    sales.order_count
FROM CustomerDetails cust
LEFT JOIN SalesAnalytics sales ON cust.c_customer_sk = sales.ws_bill_customer_sk
WHERE cust.cd_marital_status = 'M' AND cust.cd_purchase_estimate > 1000
ORDER BY sales.total_sales DESC
LIMIT 50;
