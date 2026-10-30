
WITH ranked_sales AS (
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY SUM(ss.ss_net_paid) DESC) AS rank
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_current_price > 20.00 AND ss.ss_sold_date_sk BETWEEN 21000101 AND 21001231
    GROUP BY ss.ss_sold_date_sk, ss.ss_item_sk, ss.ss_store_sk
),
top_stores AS (
    SELECT 
        rs.ss_store_sk,
        SUM(rs.total_quantity) AS store_total_quantity,
        SUM(rs.total_net_paid) AS store_total_net_paid
    FROM ranked_sales rs
    WHERE rs.rank <= 10
    GROUP BY rs.ss_store_sk
)
SELECT 
    s.s_store_name,
    ts.store_total_quantity,
    ts.store_total_net_paid
FROM top_stores ts
JOIN store s ON ts.ss_store_sk = s.s_store_sk
ORDER BY ts.store_total_net_paid DESC
LIMIT 5;
