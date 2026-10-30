
WITH RankedSales AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_net_profit) DESC) AS rank
    FROM 
        catalog_sales cs
    JOIN 
        item i ON cs.cs_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0 AND 
        cs.cs_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        cs.cs_item_sk, 
        cs.cs_order_number
),
TopItems AS (
    SELECT 
        ri.cs_item_sk,
        SUM(ri.total_quantity) AS total_quantity,
        SUM(ri.total_net_profit) AS total_net_profit
    FROM 
        RankedSales ri
    WHERE 
        ri.rank <= 10
    GROUP BY 
        ri.cs_item_sk
)
SELECT 
    i.i_item_id, 
    i.i_item_desc, 
    ti.total_quantity, 
    ti.total_net_profit
FROM 
    TopItems ti
JOIN 
    item i ON ti.cs_item_sk = i.i_item_sk
ORDER BY 
    ti.total_net_profit DESC;
