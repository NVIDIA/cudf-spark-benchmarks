
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023 
        AND cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.ws_sold_date_sk
),
monthly_sales AS (
    SELECT 
        DATE_TRUNC('month', dd.d_date) AS month,
        SUM(sd.total_sales) AS monthly_sales,
        SUM(sd.total_orders) AS monthly_orders,
        SUM(sd.total_quantity) AS monthly_quantity
    FROM 
        sales_data sd
    JOIN 
        date_dim dd ON sd.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        month
)
SELECT 
    month,
    monthly_sales,
    monthly_orders,
    monthly_quantity,
    LAG(monthly_sales) OVER (ORDER BY month) AS previous_month_sales,
    (monthly_sales - LAG(monthly_sales) OVER (ORDER BY month)) AS sales_change
FROM 
    monthly_sales
ORDER BY 
    month;
