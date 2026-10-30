
WITH  Sales_CTE AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) as rnk
    FROM 
        web_sales ws
),
Return_Summary AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned_amt,
        COUNT(DISTINCT wr.wr_order_number) AS total_return_orders
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    SUM(COALESCE(sc.ws_quantity, 0)) AS total_sold_quantity,
    SUM(COALESCE(sc.ws_sales_price, 0) * COALESCE(sc.ws_quantity, 0)) AS total_sales_value,
    COALESCE(rs.total_returned, 0) AS total_returned_quantity,
    COALESCE(rs.total_returned_amt, 0) AS total_returned_amount,
    CASE 
        WHEN SUM(COALESCE(sc.ws_quantity, 0)) > 0 THEN 
            (SUM(COALESCE(sc.ws_quantity, 0)) - COALESCE(rs.total_returned, 0)) 
        ELSE 0 
    END AS net_sales_quantity,
    ROUND(COALESCE(SUM(COALESCE(sc.ws_sales_price, 0) * COALESCE(sc.ws_quantity, 0)), 0) - COALESCE(rs.total_returned_amt, 0), 2) AS net_sales_value,
    CASE 
        WHEN SUM(COALESCE(sc.ws_quantity, 0)) > 0 AND COALESCE(rs.total_return_orders, 0) > 0 THEN 
            (COALESCE(rs.total_return_orders, 0) * 1.0 / NULLIF(SUM(COALESCE(sc.ws_quantity, 0)), 0)) * 100 
        ELSE NULL 
    END AS return_rate_percentage
FROM 
    item i
LEFT JOIN 
    Sales_CTE sc ON i.i_item_sk = sc.ws_item_sk AND sc.rnk = 1
LEFT JOIN 
    Return_Summary rs ON i.i_item_sk = rs.wr_item_sk
GROUP BY 
    i.i_item_id, i.i_product_name, COALESCE(rs.total_returned, 0), COALESCE(rs.total_returned_amt, 0), COALESCE(rs.total_return_orders, 0)
ORDER BY 
    net_sales_value DESC
LIMIT 10;
