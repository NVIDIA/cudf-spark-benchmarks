
WITH aggregated_sales AS (
    SELECT 
        c.c_customer_id AS customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        d.d_month_seq,
        d.d_year
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND d.d_month_seq BETWEEN 1 AND 6
    GROUP BY 
        c.c_customer_id, 
        d.d_month_seq, 
        d.d_year
),
top_sales AS (
    SELECT 
        customer_id,
        total_sales,
        avg_net_profit,
        total_orders,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        aggregated_sales
)
SELECT 
    ts.customer_id,
    ts.total_sales,
    ts.avg_net_profit,
    ts.total_orders
FROM 
    top_sales ts
WHERE 
    ts.sales_rank <= 10
ORDER BY 
    ts.total_sales DESC;
