
WITH sales_summary AS (
    SELECT 
        t.t_hour,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    GROUP BY 
        t.t_hour
)
SELECT 
    s.t_hour,
    COALESCE(s.total_quantity, 0) AS total_quantity,
    COALESCE(s.total_sales, 0) AS total_sales
FROM 
    (SELECT DISTINCT t_hour FROM time_dim) AS t
LEFT JOIN 
    sales_summary s ON t.t_hour = s.t_hour
ORDER BY 
    t.t_hour;
