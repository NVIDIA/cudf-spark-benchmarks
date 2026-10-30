
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        d.d_year,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, d.d_year
), customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.total_sales) AS total_sales_by_demo
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_summary ss ON c.c_customer_id = ss.c_customer_id
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd_gender,
    cd_marital_status,
    COUNT(cd_demo_sk) AS num_customers,
    SUM(total_sales_by_demo) AS total_sales
FROM 
    customer_demographics
GROUP BY 
    cd_gender, cd_marital_status
ORDER BY 
    total_sales DESC;
