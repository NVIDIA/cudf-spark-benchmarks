WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        hd.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
sales_summary AS (
    SELECT 
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        COUNT(DISTINCT ss_customer_sk) AS unique_customers,
        EXTRACT(MONTH FROM cast('2002-10-01' as date)) AS current_month
    FROM 
        store_sales 
    WHERE 
        ss_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = cast('2002-10-01' as date) - INTERVAL '30 days')
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_zip,
    ci.cd_gender,
    ci.cd_marital_status,
    ss.total_sales,
    ss.total_transactions,
    ss.unique_customers,
    CASE 
        WHEN ci.hd_income_band_sk < 5 THEN 'Low Income'
        WHEN ci.hd_income_band_sk BETWEEN 5 AND 10 THEN 'Medium Income'
        ELSE 'High Income'
    END AS income_category
FROM 
    customer_info ci
CROSS JOIN 
    sales_summary ss
WHERE 
    ci.cd_gender = 'F' 
    AND ci.cd_marital_status = 'M' 
ORDER BY 
    ss.total_sales DESC;