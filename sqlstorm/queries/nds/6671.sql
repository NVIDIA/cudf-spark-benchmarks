
WITH sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_net_paid,
        ws.ws_sales_price,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        da.d_year,
        da.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim da ON ws.ws_sold_date_sk = da.d_date_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND da.d_year BETWEEN 2019 AND 2022
),
agg_sales AS (
    SELECT 
        da.d_month_seq AS month,
        SUM(sd.ws_net_paid) AS total_net_paid,
        SUM(sd.ws_sales_price) AS total_sales_price,
        COUNT(sd.ws_order_number) AS number_of_orders,
        AVG(sd.ws_net_paid) AS avg_order_value
    FROM 
        sales_data sd
    JOIN 
        date_dim da ON sd.d_year = da.d_year
    GROUP BY 
        da.d_month_seq
)
SELECT 
    m.month,
    m.total_net_paid,
    m.total_sales_price,
    m.number_of_orders,
    m.avg_order_value,
    CASE 
        WHEN m.total_net_paid > 1000000 THEN 'High Revenue'
        WHEN m.total_net_paid > 500000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    agg_sales m
ORDER BY 
    m.month;
