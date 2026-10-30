
WITH  sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_profit,
        ROW_NUMBER() OVER (ORDER BY sd.total_net_profit DESC) AS overall_rank
    FROM 
        sales_data sd
    WHERE 
        sd.rank = 1
),
store_info AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        COUNT(ss_ticket_number) AS total_sales
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss_store_sk IS NOT NULL
    GROUP BY 
        s.s_store_sk, s.s_store_name
),
final_report AS (
    SELECT 
        ti.ws_item_sk,
        si.s_store_name,
        ti.total_quantity,
        ti.total_net_profit,
        si.total_sales,
        CASE 
            WHEN ti.total_net_profit > 1000 THEN 'High'
            WHEN ti.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM 
        top_items ti
    JOIN 
        store_info si ON ti.ws_item_sk = si.s_store_sk
)
SELECT 
    *,
    COALESCE((SELECT SUM(sr_return_quantity) FROM store_returns WHERE sr_item_sk = fr.ws_item_sk), 0) AS total_returns
FROM 
    final_report fr 
WHERE 
    profit_category = 'High'
ORDER BY 
    total_net_profit DESC
LIMIT 10;
