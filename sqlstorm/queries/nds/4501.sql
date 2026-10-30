
WITH RankedSales AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS SalesRank
    FROM
        web_sales
),
TopSellingItems AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(ts.total_quantity, 0) AS total_quantity_sold,
        COALESCE(ts.total_profit, 0) AS total_profit
    FROM 
        item i
    LEFT JOIN 
        TopSellingItems ts ON i.i_item_sk = ts.ws_item_sk
)
SELECT 
    id.i_item_id,
    id.i_item_desc,
    id.i_current_price,
    id.total_quantity_sold,
    id.total_profit,
    rs.ws_order_number,
    rs.ws_net_profit,
    rs.SalesRank
FROM 
    ItemDetails id
LEFT JOIN 
    RankedSales rs ON id.i_item_sk = rs.ws_item_sk AND rs.SalesRank <= 3
WHERE 
    (id.total_quantity_sold > 0 OR id.total_profit > 0) 
    AND id.i_current_price IS NOT NULL
ORDER BY 
    id.total_profit DESC, id.total_quantity_sold ASC, id.i_item_id;
