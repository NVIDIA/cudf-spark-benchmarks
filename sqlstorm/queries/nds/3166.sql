
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
returns_data AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned_quantity,
        SUM(wr.wr_return_amt) AS total_returned_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
final_data AS (
    SELECT 
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        COALESCE(sd.total_quantity_sold, 0) - COALESCE(rd.total_returned_quantity, 0) AS net_quantity,
        COALESCE(sd.total_sales_revenue, 0) - COALESCE(rd.total_returned_amount, 0) AS net_revenue
    FROM 
        sales_data sd
    LEFT JOIN 
        returns_data rd ON sd.ws_item_sk = rd.wr_item_sk
),
ranked_sales AS (
    SELECT 
        fd.ws_sold_date_sk,
        fd.ws_item_sk,
        fd.net_quantity,
        fd.net_revenue,
        RANK() OVER (PARTITION BY fd.ws_sold_date_sk ORDER BY fd.net_revenue DESC) AS revenue_rank
    FROM 
        final_data fd
)
SELECT 
    dd.d_date,
    rs.ws_item_sk,
    rs.net_quantity,
    rs.net_revenue,
    rs.revenue_rank
FROM 
    ranked_sales rs
JOIN 
    date_dim dd ON dd.d_date_sk = rs.ws_sold_date_sk
WHERE 
    rs.revenue_rank <= 5
ORDER BY 
    dd.d_date, rs.net_revenue DESC;
