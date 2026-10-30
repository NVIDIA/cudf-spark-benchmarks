
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        COALESCE(SUM(ws.ws_quantity), 0) AS total_sales_quantity,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_sales_value,
        c.c_customer_sk
    FROM web_sales ws
    JOIN CustomerInfo c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
),
ReturnsData AS (
    SELECT 
        COALESCE(SUM(wr.wr_return_quantity), 0) AS total_return_quantity,
        COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_value,
        c.c_customer_sk
    FROM web_returns wr
    JOIN CustomerInfo c ON wr.wr_returning_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    sd.total_sales_quantity,
    sd.total_sales_value,
    rd.total_return_quantity,
    rd.total_return_value,
    (sd.total_sales_value - rd.total_return_value) AS net_sales_value
FROM CustomerInfo ci
LEFT JOIN SalesData sd ON ci.c_customer_sk = sd.c_customer_sk
LEFT JOIN ReturnsData rd ON ci.c_customer_sk = rd.c_customer_sk
WHERE ci.ca_state IN ('CA', 'NY')
ORDER BY net_sales_value DESC
LIMIT 100;
