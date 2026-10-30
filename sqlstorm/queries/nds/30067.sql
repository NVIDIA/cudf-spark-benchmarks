
WITH  sales_data AS (
    SELECT 
        ws_item_sk, 
        sum(ws_sales_price) AS total_sales, 
        count(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY sum(ws_sales_price) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        count(DISTINCT ws_order_number) AS number_of_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_gender IS NOT NULL
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
sales_summary AS (
    SELECT 
        s.ws_item_sk,
        s.total_sales,
        ci.cd_gender,
        ci.number_of_orders
    FROM sales_data s
    JOIN customer_info ci ON s.ws_item_sk = ci.c_customer_sk
    WHERE s.rank <= 10
)
SELECT 
    s.ws_item_sk,
    s.total_sales,
    ci.cd_gender,
    ci.number_of_orders,
    SUM(s.total_sales) OVER (PARTITION BY ci.cd_gender) AS gender_total_sales,
    CASE 
        WHEN ci.number_of_orders > 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS buyer_category
FROM sales_summary s
JOIN customer_info ci ON s.ws_item_sk = ci.c_customer_sk
WHERE s.total_sales IS NOT NULL
ORDER BY s.total_sales DESC;
