
WITH  Sales_CTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
High_Performance_Items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(s.total_quantity, 0) AS total_quantity,
        COALESCE(s.total_net_profit, 0) AS total_net_profit
    FROM 
        item i
    LEFT JOIN 
        Sales_CTE s ON i.i_item_sk = s.ws_item_sk
    WHERE 
        s.profit_rank <= 10 OR s.profit_rank IS NULL
),
Store_Item_Sales AS (
    SELECT 
        st.s_store_id,
        i.i_item_id,
        SUM(ss.ss_quantity) AS store_total_quantity,
        SUM(ss.ss_net_profit) AS store_total_net_profit
    FROM 
        store st
    JOIN 
        store_sales ss ON st.s_store_sk = ss.ss_store_sk
    JOIN 
        item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY 
        st.s_store_id, i.i_item_id
)
SELECT 
    hpi.i_item_id,
    hpi.i_item_desc,
    hpi.total_quantity AS web_total_quantity,
    hpi.total_net_profit AS web_total_net_profit,
    COALESCE(ss.store_total_quantity, 0) AS store_total_quantity,
    COALESCE(ss.store_total_net_profit, 0) AS store_total_net_profit
FROM 
    High_Performance_Items hpi
LEFT JOIN 
    Store_Item_Sales ss ON hpi.i_item_id = ss.i_item_id
WHERE 
    hpi.total_net_profit > (
        SELECT 
            AVG(total_net_profit) * 1.1 
        FROM 
            High_Performance_Items
    )
ORDER BY 
    hpi.total_net_profit DESC, hpi.total_quantity DESC;
