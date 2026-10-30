
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_sales_price, 
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) as rn,
        CASE 
            WHEN ws.ws_quantity = 0 THEN NULL 
            ELSE ws.ws_sales_price / NULLIF(ws.ws_quantity, 0) 
        END as avg_price
    FROM web_sales ws
    WHERE ws.ws_sales_price IS NOT NULL
), sales_summary AS (
    SELECT 
        item.i_item_id,
        SUM(rs.ws_sales_price) AS total_sales,
        AVG(rs.avg_price) AS avg_price_per_unit,
        COUNT(DISTINCT rs.ws_order_number) AS order_count
    FROM ranked_sales rs
    JOIN item ON rs.ws_item_sk = item.i_item_sk
    WHERE rs.rn = 1
    GROUP BY item.i_item_id
), store_summary AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(ss.ss_ticket_number) AS transactions,
        MAX(ss.ss_sales_price) AS max_sale
    FROM store_sales ss
    GROUP BY ss.ss_store_sk
), demographic_summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
)
SELECT 
    ss.total_sales,
    ss.avg_price_per_unit,
    ss.order_count,
    st.total_net_profit,
    st.transactions,
    ds.customer_count,
    ds.avg_purchase_estimate
FROM sales_summary ss
FULL OUTER JOIN store_summary st ON (ss.total_sales IS NOT NULL OR st.total_net_profit IS NOT NULL)
LEFT JOIN demographic_summary ds ON (ds.customer_count IS NOT NULL AND ds.avg_purchase_estimate IS NOT NULL)
WHERE (ss.total_sales > (SELECT AVG(total_sales) FROM sales_summary) OR st.total_net_profit < 0)
AND (ds.customer_count IS NULL OR (ds.customer_count > 10 AND ds.avg_purchase_estimate IS NOT NULL))
ORDER BY ss.total_sales DESC, st.total_net_profit ASC NULLS LAST;
