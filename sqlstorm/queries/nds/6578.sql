
WITH RevenueData AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales AS ws
    JOIN 
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, d.d_year, d.d_month_seq
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        total_revenue,
        total_orders,
        avg_order_value,
        cd_gender,
        cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY total_revenue DESC) AS rank
    FROM 
        RevenueData
)
SELECT 
    cd_gender,
    cd_marital_status,
    COUNT(c_customer_id) AS customer_count,
    SUM(total_revenue) AS total_revenue,
    AVG(avg_order_value) AS avg_order_value
FROM 
    TopCustomers
WHERE 
    rank <= 10
GROUP BY 
    cd_gender, cd_marital_status
ORDER BY 
    cd_gender, cd_marital_status;
