
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
returns_data AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt) AS total_returns,
        COUNT(DISTINCT wr.wr_order_number) AS total_return_orders
    FROM web_returns wr
    GROUP BY wr.wr_returning_customer_sk
),
summary AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_orders, 0) AS total_orders,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_return_orders, 0) AS total_return_orders,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM customer_data cd
    LEFT JOIN sales_data sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
    LEFT JOIN returns_data rd ON cd.c_customer_sk = rd.wr_returning_customer_sk
)
SELECT 
    s.c_customer_sk,
    s.c_first_name,
    s.c_last_name,
    s.total_sales,
    s.total_orders,
    s.total_returns,
    s.total_return_orders,
    (s.total_sales - s.total_returns) AS net_sales,
    s.cd_gender,
    s.cd_marital_status,
    s.cd_education_status
FROM summary s
WHERE s.total_sales > 5000
ORDER BY net_sales DESC
LIMIT 100;
