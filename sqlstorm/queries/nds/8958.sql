
WITH sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit,
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq
),
ranked_sales AS (
    SELECT 
        s.*,
        RANK() OVER (PARTITION BY sales_year, sales_month ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary s
)
SELECT 
    rs.sales_year,
    rs.sales_month,
    COUNT(*) AS top_customers_count,
    AVG(total_sales) AS avg_sales,
    SUM(total_profit) AS total_profit_for_top_customers
FROM 
    ranked_sales rs
WHERE 
    rs.sales_rank <= 10
GROUP BY 
    rs.sales_year, rs.sales_month
ORDER BY 
    sales_year, sales_month;
