
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk, ws_sold_date_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(SUM(s.ws_ext_sales_price), 0) AS total_web_sales
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales s ON c.c_customer_sk = s.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
high_value_customers AS (
    SELECT 
        cus.c_customer_sk,
        cus.c_first_name,
        cus.c_last_name,
        cus.total_web_sales,
        CASE 
            WHEN cus.total_web_sales > 1000 THEN 'High Value'
            WHEN cus.total_web_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customer_summary cus
    WHERE 
        cus.total_web_sales IS NOT NULL
),
sales_dates AS (
    SELECT 
        d.d_date_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS daily_sales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date_sk
),
customer_sales_analysis AS (
    SELECT 
        hvc.customer_value,
        sd.total_orders,
        SUM(sd.daily_sales) AS total_daily_sales,
        (SELECT COUNT(*)
         FROM customer_summary cs
         WHERE cs.total_web_sales BETWEEN 500 AND 1000) AS medium_value_count
    FROM 
        high_value_customers hvc
    JOIN 
        sales_dates sd ON sd.total_orders > 0
    GROUP BY 
        hvc.customer_value, sd.total_orders
)
SELECT 
    customer_value,
    total_orders,
    total_daily_sales,
    medium_value_count
FROM 
    customer_sales_analysis
WHERE 
    customer_value <> 'Low Value'
ORDER BY 
    total_daily_sales DESC;
