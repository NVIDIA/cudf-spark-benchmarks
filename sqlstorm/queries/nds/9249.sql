
WITH Recent_Sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_web_page_sk,
        ws.ws_ship_date_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_ship_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
), 
Sales_Statistics AS (
    SELECT 
        rs.ws_item_sk,
        COUNT(rs.ws_order_number) AS total_orders,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_sales_price) AS total_sales,
        SUM(rs.ws_net_profit) AS total_profit,
        AVG(rs.ws_sales_price) AS avg_sales_price,
        d.d_month_seq
    FROM 
        Recent_Sales rs
    JOIN 
        date_dim d ON rs.ws_ship_date_sk = d.d_date_sk
    GROUP BY 
        rs.ws_item_sk, d.d_month_seq
),
Top_Products AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_orders,
        ss.total_quantity,
        ss.total_sales,
        ss.total_profit,
        ss.avg_sales_price,
        RANK() OVER (PARTITION BY ss.d_month_seq ORDER BY ss.total_quantity DESC) AS rank
    FROM 
        Sales_Statistics ss
)
SELECT 
    tp.ws_item_sk,
    tp.total_orders,
    tp.total_quantity,
    tp.total_sales,
    tp.total_profit,
    tp.avg_sales_price,
    dp.i_item_desc
FROM 
    Top_Products tp
JOIN 
    item dp ON tp.ws_item_sk = dp.i_item_sk
WHERE 
    tp.rank <= 10
ORDER BY 
    tp.total_quantity DESC, 
    tp.total_sales DESC;
