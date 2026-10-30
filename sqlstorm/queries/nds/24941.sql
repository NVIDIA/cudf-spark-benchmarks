
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        DENSE_RANK() OVER (ORDER BY ws.ws_net_profit DESC) AS dense_rank_profit
    FROM web_sales ws
    WHERE ws.ws_net_profit IS NOT NULL
),
sales_analysis AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_quantity,
        r.ws_net_profit,
        r.rank_profit,
        COALESCE(r.dense_rank_profit, 0) AS dense_rank_profit,
        (SELECT AVG(ws.ws_net_profit) 
         FROM web_sales ws 
         WHERE ws.ws_item_sk = r.ws_item_sk) AS avg_profit_item,
        CASE 
            WHEN r.ws_net_profit > (SELECT AVG(ws.ws_net_profit) 
                                     FROM web_sales ws 
                                     WHERE ws.ws_item_sk = r.ws_item_sk) 
            THEN 'Above Average' 
            ELSE 'Below Average' 
        END AS profit_performance
    FROM ranked_sales r
),
store_summary AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_sales,
        AVG(ss.ss_net_profit) AS avg_store_profit
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_sk
),
final_report AS (
    SELECT 
        sa.ws_item_sk,
        sa.ws_order_number,
        sa.ws_quantity,
        sa.ws_net_profit,
        ss.total_quantity,
        ss.total_sales,
        ss.avg_store_profit,
        (CASE 
             WHEN ss.total_quantity > 100 THEN 'High'
             WHEN ss.total_quantity BETWEEN 50 AND 100 THEN 'Medium'
             ELSE 'Low'
         END) AS sales_band,
        (SELECT COUNT(*) 
         FROM customer c 
         WHERE EXISTS (
            SELECT 1 
            FROM customer_demographics cd 
            WHERE cd.cd_demo_sk = c.c_current_cdemo_sk 
              AND cd.cd_gender = 'F'
         )) AS female_customers_count
    FROM sales_analysis sa
    LEFT JOIN store_summary ss ON sa.ws_item_sk = ss.s_store_sk
)
SELECT 
    fr.ws_item_sk,
    fr.ws_order_number,
    fr.ws_quantity,
    fr.ws_net_profit,
    fr.total_quantity,
    fr.total_sales,
    fr.avg_store_profit,
    fr.sales_band,
    fr.female_customers_count
FROM final_report fr
WHERE fr.ws_net_profit IS NOT NULL
  AND EXISTS (
        SELECT 1 
        FROM item it 
        WHERE it.i_item_sk = fr.ws_item_sk 
          AND (it.i_current_price > 20 OR it.i_current_price IS NULL)
    )
ORDER BY fr.ws_net_profit DESC, fr.total_sales ASC
LIMIT 100;
