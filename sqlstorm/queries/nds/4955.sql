
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
returns_summary AS (
    SELECT 
        wr_item_sk,
        COUNT(wr_order_number) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
items AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        COALESCE(ss.total_quantity_sold, 0) AS total_quantity_sold,
        COALESCE(ss.total_net_profit, 0) AS total_net_profit,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN COALESCE(ss.total_net_profit, 0) = 0 THEN 'No Profit'
            WHEN COALESCE(rs.total_returns, 0) > 0 THEN 'Returns'
            ELSE 'Regular'
        END AS sales_type
    FROM 
        item i
    LEFT JOIN 
        sales_summary ss ON i.i_item_sk = ss.ws_item_sk
    LEFT JOIN 
        returns_summary rs ON i.i_item_sk = rs.wr_item_sk
)
SELECT 
    i.i_item_sk,
    i.i_product_name,
    i.total_quantity_sold,
    i.total_net_profit,
    i.total_returns,
    i.total_return_amount,
    i.sales_type,
    CASE 
        WHEN i.total_net_profit > 1000 THEN 'High Profit'
        WHEN i.total_net_profit > 500 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    items i
WHERE 
    i.sales_type = 'Regular' 
    OR (i.sales_type = 'Returns' AND i.total_returns > 5)
ORDER BY 
    i.total_net_profit DESC
LIMIT 10;
