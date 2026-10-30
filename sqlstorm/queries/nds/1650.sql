
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT cr_order_number) AS total_returns
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    ci.customer_name,
    ci.ca_city,
    ci.ca_state,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(sd.total_profit, 0) AS total_profit,
    CASE 
        WHEN COALESCE(sd.total_sales, 0) > 0 THEN (COALESCE(cr.total_returned_quantity, 0) * 100.0 / COALESCE(sd.total_sales, 1))
        ELSE 0
    END AS return_rate_percentage
FROM CustomerInfo ci
LEFT JOIN SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
LEFT JOIN CustomerReturns cr ON ci.c_customer_sk = cr.cr_returning_customer_sk
WHERE 
    ci.cd_marital_status = 'M' 
    AND ci.cd_gender = 'F'
    AND (ci.cd_purchase_estimate >= 5000 OR ci.ca_state IS NOT NULL)
ORDER BY total_sales DESC, return_rate_percentage ASC
LIMIT 100;
