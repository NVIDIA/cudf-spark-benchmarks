
WITH sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
return_summary AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt) AS total_returned_amount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
final_summary AS (
    SELECT 
        ss.ws_item_sk,
        COALESCE(ss.total_quantity, 0) AS total_quantity,
        COALESCE(ss.total_net_paid, 0) AS total_net_paid,
        COALESCE(rs.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(rs.total_returned_amount, 0) AS total_returned_amount,
        COALESCE(ss.total_quantity, 0) - COALESCE(rs.total_returned_quantity, 0) AS net_sales_quantity,
        COALESCE(ss.total_net_paid, 0) - COALESCE(rs.total_returned_amount, 0) AS net_sales_amount
    FROM 
        sales_summary ss
    LEFT JOIN 
        return_summary rs ON ss.ws_item_sk = rs.wr_item_sk
)
SELECT 
    f.ws_item_sk,
    f.total_quantity,
    f.total_net_paid,
    f.total_returned_quantity,
    f.total_returned_amount,
    f.net_sales_quantity,
    f.net_sales_amount,
    CASE 
        WHEN f.net_sales_amount > 0 THEN ROUND((f.net_sales_amount / NULLIF(f.total_net_paid, 0)) * 100, 2)
        ELSE 0 
    END AS sales_performance_percentage
FROM 
    final_summary f
INNER JOIN 
    item i ON f.ws_item_sk = i.i_item_sk
WHERE 
    i.i_current_price > 10.00
ORDER BY 
    f.net_sales_amount DESC
LIMIT 100;
