
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) as sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
)

SELECT 
    i.i_item_id,
    i.i_item_desc,
    SUM(rs.ws_sales_price) AS total_sales,
    SUM(rs.ws_ext_discount_amt) AS total_discount,
    SUM(rs.ws_net_profit) AS total_profit
FROM 
    RankedSales rs
JOIN 
    item i ON rs.ws_item_sk = i.i_item_sk
WHERE 
    rs.sales_rank <= 10
GROUP BY 
    i.i_item_id, i.i_item_desc
ORDER BY 
    total_profit DESC;
