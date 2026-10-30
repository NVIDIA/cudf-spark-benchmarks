
WITH  sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_net_paid
    FROM catalog_sales 
    GROUP BY cs_sold_date_sk, cs_item_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(COALESCE(ws.ws_net_paid_inc_tax, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
item_stats AS (
    SELECT
        i.i_item_sk, 
        i.i_item_id,
        AVG(i.i_current_price) AS avg_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE i.i_rec_start_date <= DATE '2002-10-01' 
        AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > DATE '2002-10-01')
    GROUP BY i.i_item_sk, i.i_item_id
),
top_items AS (
    SELECT 
        item_stats.i_item_id,
        SUM(sales_data.total_quantity) AS total_quantity_sold,
        RANK() OVER (ORDER BY SUM(sales_data.total_quantity) DESC) AS item_rank
    FROM item_stats 
    JOIN sales_data ON item_stats.i_item_sk = sales_data.ws_item_sk
    GROUP BY item_stats.i_item_id
)
SELECT 
    cs.c_customer_sk,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_spent,
    ti.i_item_id,
    ti.total_quantity_sold
FROM customer_stats cs
JOIN top_items ti ON cs.c_customer_sk = (
    SELECT sr_customer_sk 
    FROM store_returns 
    WHERE sr_return_quantity > 0 
    ORDER BY sr_return_amt DESC 
    LIMIT 1
)
WHERE cs.total_spent > (SELECT AVG(total_spent) FROM customer_stats)
ORDER BY cs.total_spent DESC, ti.total_quantity_sold DESC;
