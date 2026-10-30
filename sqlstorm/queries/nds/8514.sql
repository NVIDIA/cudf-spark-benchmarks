WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450508 AND 2450510 
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
TopSales AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
)
SELECT 
    ts.c_customer_id,
    ts.c_first_name,
    ts.c_last_name,
    ts.total_sales,
    ts.total_orders,
    ts.avg_net_profit
FROM 
    TopSales ts
WHERE 
    ts.sales_rank <= 10
ORDER BY 
    ts.total_sales DESC;