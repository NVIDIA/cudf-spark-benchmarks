
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.ws_sold_date_sk
),
avg_sales AS (
    SELECT 
        AVG(total_sales) AS avg_daily_sales,
        AVG(total_discount) AS avg_daily_discount,
        AVG(total_orders) AS avg_daily_orders
    FROM 
        sales_data
),
top_sales_dates AS (
    SELECT 
        d.d_date AS sales_date,
        sd.total_sales
    FROM 
        sales_data sd
    JOIN 
        date_dim d ON sd.ws_sold_date_sk = d.d_date_sk
    ORDER BY 
        sd.total_sales DESC
    LIMIT 5
)
SELECT 
    a.avg_daily_sales,
    a.avg_daily_discount,
    a.avg_daily_orders,
    t.sales_date,
    t.total_sales
FROM 
    avg_sales a
JOIN 
    top_sales_dates t ON true;
