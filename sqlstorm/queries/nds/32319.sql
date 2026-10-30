
WITH  sales_summary AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(ss.ss_net_profit) DESC) AS rank
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
),
most_profitable_items AS (
    SELECT 
        si.i_item_sk,
        si.i_item_id,
        SUM(ss.ss_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY si.i_item_sk ORDER BY SUM(ss.ss_net_profit) DESC) AS item_rank
    FROM 
        item si
    JOIN 
        store_sales ss ON si.i_item_sk = ss.ss_item_sk
    GROUP BY 
        si.i_item_sk, si.i_item_id
),
customer_returns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    s_store.s_store_id,
    s_store.s_store_name,
    COALESCE(ss.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(ss.total_net_profit, 0) AS total_net_profit,
    item_summary.i_item_id,
    item_summary.total_profit,
    returns.total_returns,
    returns.total_return_amount
FROM 
    store s_store
LEFT JOIN 
    sales_summary ss ON s_store.s_store_sk = ss.s_store_sk
JOIN 
    most_profitable_items item_summary ON ss.total_net_profit > 0
LEFT JOIN 
    customer_returns returns ON item_summary.i_item_sk = returns.cr_item_sk
WHERE 
    ss.rank <= 10 AND item_summary.item_rank <= 5
ORDER BY 
    total_net_profit DESC, total_profit DESC;
