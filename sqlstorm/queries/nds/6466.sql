
WITH sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE
        ws_sales_price > 0
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
demographics_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(sf.total_sales) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        sales_summary sf ON ws.ws_item_sk = sf.ws_item_sk AND ws.ws_sold_date_sk = sf.ws_sold_date_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
active_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name, 
        c.c_last_name,
        ds.d_year,
        ds.d_month_seq
    FROM 
        customer c
    JOIN 
        date_dim ds ON c.c_first_sales_date_sk = ds.d_date_sk
    WHERE 
        ds.d_year = 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ds.d_year, ds.d_month_seq
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    COUNT(DISTINCT a.c_customer_sk) AS active_customers_count,
    SUM(d.total_spent) AS total_spent_by_gender_and_marital_status,
    AVG(d.order_count) AS avg_orders_per_customer
FROM 
    demographics_summary d
JOIN 
    active_customers a ON d.c_customer_sk = a.c_customer_sk
GROUP BY 
    d.cd_gender, d.cd_marital_status
ORDER BY 
    total_spent_by_gender_and_marital_status DESC;
