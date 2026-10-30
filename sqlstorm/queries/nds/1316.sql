
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0
),
total_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales_price,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
return_stats AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt) AS total_returned_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    item.i_item_id,
    item.i_product_name,
    COALESCE(ts.total_sales_price, 0) AS total_sales_price,
    COALESCE(rs.total_returns, 0) AS total_returns,
    rs.total_returned_amount,
    ROUND(COALESCE(ts.total_sales_price, 0) / NULLIF(COALESCE(rs.total_returns, 0), 0), 2) AS sales_per_return,
    COUNT(DISTINCT customer.c_customer_id) AS unique_customers
FROM 
    item 
LEFT JOIN 
    total_sales ts ON item.i_item_sk = ts.ws_item_sk
LEFT JOIN 
    return_stats rs ON item.i_item_sk = rs.wr_item_sk
JOIN 
    web_sales ws ON item.i_item_sk = ws.ws_item_sk
JOIN 
    customer ON ws.ws_bill_customer_sk = customer.c_customer_sk
GROUP BY 
    item.i_item_id, item.i_product_name, ts.total_sales_price, rs.total_returns, rs.total_returned_amount
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 10
ORDER BY 
    sales_per_return DESC;
