
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COALESCE(cd.cd_marital_status, 'U') AS marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
TopItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales
    FROM SalesData sd
    WHERE sd.sales_rank <= 10
)
SELECT 
    ci.ws_item_sk,
    COALESCE(cd.gender, 'Unknown') AS gender,
    COALESCE(cd.marital_status, 'U') AS marital_status,
    SUM(ci.total_sales) AS total_sales,
    SUM(ci.total_quantity) AS total_quantity,
    COUNT(DISTINCT cd.c_customer_sk) AS distinct_customers
FROM TopItems ci
LEFT JOIN CustomerData cd ON cd.order_count > 0
GROUP BY ci.ws_item_sk, cd.gender, cd.marital_status
ORDER BY total_sales DESC
LIMIT 25 OFFSET 0;
