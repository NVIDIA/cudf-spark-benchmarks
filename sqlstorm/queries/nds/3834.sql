
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
returned_item_summary AS (
    SELECT 
        wr_item_sk,
        COUNT(wr_order_number) AS total_returns,
        SUM(wr_return_amt) AS total_returned_amount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
best_selling_items AS (
    SELECT 
        i_item_sk,
        i_product_name,
        i_current_price,
        ss.total_quantity,
        ss.total_net_profit,
        COALESCE(ris.total_returns, 0) AS total_returns,
        COALESCE(ris.total_returned_amount, 0) AS total_returned_amount,
        (ss.total_net_profit - COALESCE(ris.total_returned_amount, 0)) AS net_profit_after_returns
    FROM 
        item
    JOIN 
        sales_summary ss ON item.i_item_sk = ss.ws_item_sk
    LEFT JOIN 
        returned_item_summary ris ON item.i_item_sk = ris.wr_item_sk
    ORDER BY 
        net_profit_after_returns DESC
)
SELECT 
    bsi.i_item_sk,
    bsi.i_product_name,
    bsi.i_current_price,
    bsi.total_quantity,
    bsi.total_net_profit,
    bsi.total_returns,
    bsi.total_returned_amount,
    bsi.net_profit_after_returns
FROM 
    best_selling_items bsi
WHERE 
    bsi.net_profit_after_returns > 1000
    AND bsi.total_quantity > 50
    AND bsi.i_current_price IS NOT NULL
UNION ALL
SELECT 
    bsi.i_item_sk,
    bsi.i_product_name,
    bsi.i_current_price,
    bsi.total_quantity,
    bsi.total_net_profit,
    bsi.total_returns,
    bsi.total_returned_amount,
    bsi.net_profit_after_returns
FROM 
    best_selling_items bsi
WHERE 
    bsi.net_profit_after_returns <= 1000
    AND bsi.total_quantity <= 50
ORDER BY 
    net_profit_after_returns DESC;
