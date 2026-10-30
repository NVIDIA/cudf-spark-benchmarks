
WITH CustomerStats AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_purchase
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_purchase_estimate IS NOT NULL
),
SalesData AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY
        ws.ws_bill_customer_sk
),
CombinedStats AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_purchase_estimate,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.total_orders, 0) AS total_orders
    FROM
        CustomerStats cs
    LEFT JOIN
        SalesData sd ON cs.c_customer_sk = sd.customer_sk
)
SELECT
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.total_sales,
    c.total_orders,
    CASE 
        WHEN c.total_sales > 1000 THEN 'High Value'
        WHEN c.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value,
    c.cd_marital_status
FROM
    CombinedStats c
WHERE
    (c.cd_gender = 'F' AND c.total_sales > 500)
    OR (c.cd_gender = 'M' AND c.total_sales > 1000)
ORDER BY
    c.total_sales DESC
LIMIT 10;
