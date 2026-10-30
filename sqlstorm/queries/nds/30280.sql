
WITH  sales_summary AS (
    SELECT
        ss_store_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS rank
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
      AND ss_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ss_store_sk
),
customer_stats AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(ws.ws_order_number) AS total_orders,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
popular_items AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY i.i_item_id, i.i_item_desc
    HAVING SUM(ws.ws_quantity) > 100
),
top_stores AS (
    SELECT 
        ss.ss_store_sk,
        ss.total_quantity,
        ss.total_sales,
        ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS store_rank
    FROM sales_summary ss
)
SELECT
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    pi.i_item_desc,
    pi.total_quantity_sold,
    ts.total_sales,
    CASE 
        WHEN cs.total_spent > 5000 THEN 'High Roller'
        WHEN cs.total_spent BETWEEN 1000 AND 5000 THEN 'Regular'
        ELSE 'Occasional'
    END AS customer_category
FROM customer_stats cs
LEFT JOIN popular_items pi ON cs.total_orders > 0
LEFT JOIN top_stores ts ON cs.c_customer_sk = ts.ss_store_sk
WHERE ts.store_rank <= 10
  AND cs.total_orders IS NOT NULL
ORDER BY cs.total_spent DESC, pi.total_quantity_sold DESC
LIMIT 100;
