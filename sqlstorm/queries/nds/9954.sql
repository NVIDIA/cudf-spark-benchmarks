
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
gender_distribution AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        SUM(total_sales) AS total_sales,
        SUM(total_orders) AS total_orders,
        AVG(total_sales) AS avg_sales_per_customer
    FROM 
        sales_summary
    GROUP BY 
        cd_gender
)
SELECT 
    gd.cd_gender,
    gd.customer_count,
    gd.total_sales,
    gd.total_orders,
    gd.avg_sales_per_customer,
    CASE 
        WHEN gd.avg_sales_per_customer > 1000 THEN 'High Value'
        WHEN gd.avg_sales_per_customer BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    gender_distribution gd
ORDER BY 
    gd.total_sales DESC;
