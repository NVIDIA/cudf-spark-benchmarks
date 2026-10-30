
WITH AddressProcessing AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
CustomerProcessing AS (
    SELECT 
        c_customer_sk,
        CONCAT(TRIM(c_first_name), ' ', TRIM(c_last_name)) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesAggregated AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS orders_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
ReturnedSales AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt_inc_tax) AS total_returns,
        COUNT(wr_order_number) AS returns_count
    FROM web_returns
    GROUP BY wr_returning_customer_sk
)

SELECT 
    a.full_address,
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    (COALESCE(s.total_sales, 0) - COALESCE(r.total_returns, 0)) AS net_sales
FROM AddressProcessing a
JOIN CustomerProcessing c ON c.c_customer_sk = a.ca_address_sk
LEFT JOIN SalesAggregated s ON s.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN ReturnedSales r ON r.wr_returning_customer_sk = c.c_customer_sk
WHERE ca_state = 'CA' AND c.cd_purchase_estimate > 1000
ORDER BY net_sales DESC
LIMIT 100;
