
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        hd.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
high_value_customers AS (
    SELECT 
        cs.*, 
        ss.total_sales,
        ss.total_orders 
    FROM 
        customer_details cs
    JOIN 
        sales_summary ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        ss.total_sales > (SELECT AVG(total_sales) FROM sales_summary)
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.ca_city,
    c.ca_state,
    c.cd_gender,
    c.cd_marital_status,
    CASE 
        WHEN c.hd_income_band_sk IS NULL THEN 'Unspecified'
        ELSE CAST(c.hd_income_band_sk AS STRING)
    END AS income_band,
    COALESCE(c.total_sales, 0) AS total_sales,
    COALESCE(c.total_orders, 0) AS total_orders
FROM 
    high_value_customers c
ORDER BY 
    c.total_sales DESC
LIMIT 100;
