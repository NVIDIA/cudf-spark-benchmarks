
WITH sales_data AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        i.i_item_id,
        i.i_category,
        d.d_year,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        c.c_customer_id, i.i_item_id, i.i_category, d.d_year, gender
),
ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY d_year, gender ORDER BY total_profit DESC) AS profit_rank
    FROM 
        sales_data
),
top_sales AS (
    SELECT 
        *,
        DENSE_RANK() OVER (PARTITION BY d_year ORDER BY total_orders DESC) AS order_rank
    FROM 
        ranked_sales
    WHERE 
        profit_rank <= 10
)
SELECT 
    d_year,
    gender,
    COUNT(*) AS customer_count,
    SUM(total_profit) AS total_profit,
    AVG(avg_net_paid) AS avg_net_paid
FROM 
    top_sales
GROUP BY 
    d_year, gender
ORDER BY 
    d_year, gender;
