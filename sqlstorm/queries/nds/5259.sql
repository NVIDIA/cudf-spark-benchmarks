
WITH sales_data AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS average_order_value,
        d.d_year,
        dd.d_month_seq
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        date_dim dd ON d.d_date_sk = dd.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023 AND
        c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year, dd.d_month_seq
), ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
    FROM 
        sales_data
)
SELECT 
    d_year,
    d_month_seq,
    COUNT(*) AS num_top_customers,
    SUM(total_profit) AS total_profit_sum,
    AVG(average_order_value) AS average_top_order_value
FROM 
    ranked_sales
WHERE 
    profit_rank <= 10
GROUP BY 
    d_year, d_month_seq
ORDER BY 
    d_year, d_month_seq;
