
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS average_profit,
        d.d_year
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        c.c_customer_id, cd.cd_gender, d.d_year
),
ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    r.c_customer_id,
    r.cd_gender,
    r.total_sales,
    r.order_count,
    r.average_profit,
    r.d_year
FROM 
    ranked_sales r
WHERE 
    r.sales_rank <= 5
ORDER BY 
    r.d_year, r.sales_rank;
