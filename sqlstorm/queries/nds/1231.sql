
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 
        (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-10-01') AND 
        (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-10-31')
    GROUP BY ws_item_sk
),
TopItems AS (
    SELECT ws_item_sk 
    FROM RankedSales 
    WHERE sales_rank <= 5
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        CASE 
            WHEN cd.cd_credit_rating IS NULL THEN 'Unknown'
            ELSE cd.cd_credit_rating
        END AS credit_rating
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year < 1980
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.credit_rating,
    ti.ws_item_sk,
    rs.total_sales
FROM TopItems ti
JOIN RankedSales rs ON ti.ws_item_sk = rs.ws_item_sk
JOIN CustomerInfo ci ON ci.c_customer_sk IN (
    SELECT DISTINCT ws_bill_customer_sk 
    FROM web_sales ws 
    WHERE ws.ws_item_sk = ti.ws_item_sk
)
ORDER BY rs.total_sales DESC, ci.c_last_name ASC
LIMIT 10;
