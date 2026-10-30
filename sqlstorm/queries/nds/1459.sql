
WITH SalesAggregated AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
ReturnsAggregated AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_amt) AS total_return_amount,
        COUNT(wr_order_number) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
SalesReturns AS (
    SELECT 
        sa.ws_item_sk,
        sa.total_sales,
        sa.total_quantity,
        COALESCE(ra.total_return_amount, 0) AS total_return_amount,
        COALESCE(ra.total_returns, 0) AS total_returns
    FROM 
        SalesAggregated sa
    LEFT JOIN 
        ReturnsAggregated ra ON sa.ws_item_sk = ra.wr_item_sk
),
TopItems AS (
    SELECT 
        s.ws_item_sk,
        s.total_sales,
        s.total_quantity,
        s.total_return_amount,
        s.total_returns,
        ROW_NUMBER() OVER (ORDER BY (s.total_sales - s.total_return_amount) DESC) AS sales_rank
    FROM 
        SalesReturns s
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(t.total_sales, 0) AS net_sales,
    COALESCE(t.total_returns, 0) AS total_returns,
    (COALESCE(t.total_sales, 0) - COALESCE(t.total_return_amount, 0)) AS net_profit,
    CASE 
        WHEN i.i_current_price IS NOT NULL AND i.i_current_price > 0 
        THEN ROUND((COALESCE(t.total_sales, 0) - COALESCE(t.total_return_amount, 0)) / i.i_current_price, 2) 
        ELSE NULL 
    END AS sales_to_price_ratio,
    CASE 
        WHEN t.total_quantity > 0 
        THEN ROUND((COALESCE(t.total_return_amount, 0) / t.total_quantity), 2) 
        ELSE NULL 
    END AS return_per_quantity
FROM 
    TopItems t
JOIN 
    item i ON t.ws_item_sk = i.i_item_sk
WHERE 
    t.sales_rank <= 10
ORDER BY 
    net_profit DESC;
