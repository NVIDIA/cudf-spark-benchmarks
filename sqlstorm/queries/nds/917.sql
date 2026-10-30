
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
returns_summary AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
final_summary AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity_sold,
        COALESCE(rs.total_returns, 0) AS total_returns,
        (ss.total_sales_amount - COALESCE(rs.total_returns * (SELECT AVG(ws.ws_ext_sales_price) FROM web_sales ws WHERE ws.ws_item_sk = ss.ws_item_sk), 0)) AS net_sales_amount,
        ss.sales_rank
    FROM 
        sales_summary ss
    LEFT JOIN 
        returns_summary rs ON ss.ws_item_sk = rs.wr_item_sk
    WHERE 
        ss.sales_rank <= 10
)
SELECT 
    fa.ws_item_sk,
    fa.total_quantity_sold,
    fa.total_returns,
    fa.net_sales_amount,
    COALESCE(ca.ca_city, 'Unknown') AS city,
    COALESCE(ca.ca_state, 'XX') AS state
FROM 
    final_summary fa
LEFT JOIN 
    item i ON fa.ws_item_sk = i.i_item_sk
LEFT JOIN 
    customer_address ca ON i.i_item_sk = ca.ca_address_sk
WHERE 
    fa.net_sales_amount > 0
ORDER BY 
    fa.net_sales_amount DESC
LIMIT 20;
