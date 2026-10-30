
WITH daily_sales AS (
    SELECT 
        d.d_date AS sales_date,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_units,
        AVG(ws.ws_sales_price) AS avg_price
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_date
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS customer_total
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
    ORDER BY 
        customer_total DESC
    LIMIT 10
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS demographic_sales
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    ds.sales_date,
    ds.total_sales,
    ds.total_orders,
    ds.total_units,
    ds.avg_price,
    tc.customer_total,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.demographic_sales
FROM 
    daily_sales AS ds
LEFT JOIN 
    top_customers AS tc ON ds.sales_date = (SELECT MAX(sales_date) FROM daily_sales)
LEFT JOIN 
    customer_demographics AS cd ON cd.cd_demo_sk = (SELECT cd.cd_demo_sk FROM customer_demographics cd ORDER BY cd.demographic_sales DESC LIMIT 1)
ORDER BY 
    ds.sales_date DESC;
