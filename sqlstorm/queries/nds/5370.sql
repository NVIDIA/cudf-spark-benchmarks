
WITH SalesData AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND
        d.d_month_seq BETWEEN 1 AND 12
    GROUP BY 
        c.c_customer_id, 
        c.c_first_name,
        c.c_last_name
    HAVING 
        SUM(ws.ws_ext_sales_price) > 500
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    sd.total_sales,
    sd.avg_profit,
    sd.order_count,
    ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS rank
FROM 
    SalesData sd
JOIN 
    customer c ON sd.c_customer_id = c.c_customer_id
ORDER BY 
    sd.total_sales DESC
LIMIT 10;
