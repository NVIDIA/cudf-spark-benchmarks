
WITH sales_summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year IN (2022, 2023) 
        AND i.i_current_price > 20.00
    GROUP BY 
        d.d_year, 
        d.d_month_seq, 
        i.i_item_id
)
SELECT 
    ss.d_year,
    ss.d_month_seq,
    COUNT(DISTINCT ss.i_item_id) AS item_count,
    SUM(ss.total_quantity) AS total_sales_quantity,
    SUM(ss.total_sales) AS total_sales_value,
    AVG(ss.avg_net_profit) AS avg_net_profit_margin
FROM 
    sales_summary ss
JOIN 
    customer c ON ss.i_item_id = c.c_customer_id
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY 
    ss.d_year, 
    ss.d_month_seq
ORDER BY 
    ss.d_year, 
    ss.d_month_seq;
