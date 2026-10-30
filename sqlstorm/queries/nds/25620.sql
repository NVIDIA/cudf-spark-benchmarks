
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        a.ca_city,
        a.ca_state,
        a.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
ReturnsData AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt) AS total_returns,
        COUNT(wr.wr_order_number) AS return_count
    FROM web_returns wr
    GROUP BY wr.wr_returning_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.order_count, 0) AS order_count,
    COALESCE(rd.total_returns, 0) AS total_returns,
    COALESCE(rd.return_count, 0) AS return_count,
    (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_returns, 0)) AS net_sales
FROM CustomerInfo ci
LEFT JOIN SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
LEFT JOIN ReturnsData rd ON ci.c_customer_sk = rd.wr_returning_customer_sk
WHERE ci.cd_gender = 'F'
ORDER BY net_sales DESC
LIMIT 100;
