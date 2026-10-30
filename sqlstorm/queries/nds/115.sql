
WITH sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
), 
customer_data AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT cs_order_number) AS total_orders,
        COUNT(DISTINCT ws_order_number) AS web_orders,
        COALESCE(SUM(cs_ext_sales_price), 0) AS catalog_sales,
        COALESCE(SUM(ws_ext_sales_price), 0) AS web_sales
    FROM customer c
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c_customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        sd.total_orders,
        sd.web_orders,
        sd.catalog_sales,
        sd.web_sales
    FROM customer_data sd
    JOIN customer c ON sd.c_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE sd.total_orders > 5
      AND (cd.cd_marital_status = 'M' OR cd.cd_gender = 'F')
)
SELECT 
    tc.c_customer_sk,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_credit_rating,
    COALESCE(sd.total_sold, 0) AS total_items_sold,
    COALESCE(sd.total_revenue, 0) AS total_revenue,
    CASE 
        WHEN tc.web_sales > tc.catalog_sales THEN 'Web Dominant'
        ELSE 'Catalog Dominant'
    END AS sales_dominance
FROM top_customers tc
LEFT JOIN sales_data sd ON tc.c_customer_sk = sd.ws_item_sk
WHERE sd.rank <= 10
ORDER BY tc.total_orders DESC, total_revenue DESC;
