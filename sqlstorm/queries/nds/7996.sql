
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_value,
        AVG(ws.ws_net_profit) AS average_net_profit,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2022
    GROUP BY 
        ws.ws_item_sk, d.d_year, d.d_month_seq
),
HighPerformers AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity_sold,
        sd.total_sales_value,
        sd.average_net_profit,
        ROW_NUMBER() OVER (PARTITION BY sd.d_year ORDER BY sd.total_sales_value DESC) AS sales_rank,
        sd.d_year
    FROM 
        SalesData sd
    WHERE 
        sd.total_sales_value > 1000
)
SELECT 
    h.ws_item_sk,
    h.total_quantity_sold,
    h.total_sales_value,
    h.average_net_profit,
    d.d_month_seq,
    h.d_year
FROM 
    HighPerformers h
JOIN 
    date_dim d ON h.d_year = d.d_year
WHERE 
    h.sales_rank <= 10
ORDER BY 
    h.total_sales_value DESC;
