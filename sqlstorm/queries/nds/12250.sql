
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_sold_date_sk
)
SELECT 
    d.d_date AS sale_date,
    sd.total_quantity,
    sd.total_sales,
    sd.total_profit
FROM 
    sales_data sd
JOIN 
    date_dim d ON sd.ws_sold_date_sk = d.d_date_sk
ORDER BY 
    d.d_date;
