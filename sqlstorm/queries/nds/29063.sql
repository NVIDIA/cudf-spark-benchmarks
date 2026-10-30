
WITH refined_address AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, COALESCE(ca_suite_number, ''))) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
demographic_analysis AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(DISTINCT c_customer_sk) AS total_customers
    FROM 
        customer_demographics 
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status, cd_education_status
),
item_details AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_brand,
        i_current_price
    FROM 
        item
),
sales_metrics AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_sales_price) AS total_revenue
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
),
analytical_report AS (
    SELECT 
        da.cd_demo_sk,
        da.total_customers,
        ad.full_address,
        sm.total_sold,
        sm.total_revenue,
        id.i_item_desc,
        id.i_brand,
        id.i_current_price
    FROM 
        demographic_analysis da
    JOIN 
        refined_address ad ON da.cd_demo_sk = ad.ca_address_sk
    JOIN 
        sales_metrics sm ON ad.ca_city = 'San Francisco'
    JOIN 
        item_details id ON sm.ws_item_sk = id.i_item_sk
    ORDER BY 
        da.total_customers DESC, sm.total_revenue DESC
)
SELECT 
    *
FROM 
    analytical_report
LIMIT 100;
