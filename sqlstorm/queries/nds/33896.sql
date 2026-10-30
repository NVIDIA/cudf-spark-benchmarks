
WITH  monthly_sales AS (
    SELECT 
        d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        date_dim
    JOIN 
        web_sales ON d_date_sk = ws_sold_date_sk
    GROUP BY 
        d_year
), top_monthly_sales AS (
    SELECT 
        d_year,
        total_sales,
        sales_rank
    FROM 
        monthly_sales
    WHERE 
        sales_rank <= 5
), customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN 
        customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
), sales_summary AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer_info ci
    JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = ci.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year IN (2021, 2022))
    GROUP BY 
        ci.full_name, ci.cd_gender, ci.cd_marital_status, ci.cd_purchase_estimate
)
SELECT 
    s.full_name,
    s.cd_gender,
    s.cd_marital_status,
    s.total_sales,
    CASE 
        WHEN s.total_sales > 1000 THEN 'High Value'
        WHEN s.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    tms.total_sales AS top_sales
FROM 
    sales_summary s
LEFT JOIN 
    top_monthly_sales tms ON tms.total_sales = (SELECT MAX(total_sales) FROM sales_summary)
WHERE 
    s.total_sales IS NOT NULL
ORDER BY 
    s.total_sales DESC;
