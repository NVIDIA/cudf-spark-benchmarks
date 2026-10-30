
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
), CombinedData AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.ca_city,
        ci.ca_state,
        ci.ca_zip,
        ci.ca_country,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.order_count, 0) AS order_count
    FROM CustomerInfo ci
    LEFT JOIN SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN cd_credit_rating = 'Excellent' THEN 'High Value Customer'
        WHEN total_sales > 1000 THEN 'Potential Loyal Customer'
        ELSE 'Regular Customer'
    END AS customer_segment,
    CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
FROM CombinedData
WHERE cd_gender = 'F' AND cd_marital_status = 'M'
ORDER BY total_sales DESC
LIMIT 100;
