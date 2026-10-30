
WITH  sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_first_name) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        hd.hd_income_band_sk IS NOT NULL
),
sales_summary AS (
    SELECT
        sh.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS number_of_orders
    FROM 
        sales_hierarchy sh
    JOIN 
        web_sales ws ON sh.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        sh.c_customer_sk
),
most_active_customers AS (
    SELECT 
        ss.c_customer_sk,
        ss.total_sales,
        ss.number_of_orders,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS rank
    FROM 
        sales_summary ss
)
SELECT 
    sh.c_first_name,
    sh.c_last_name,
    sh.c_email_address,
    mac.total_sales,
    mac.number_of_orders,
    mac.rank
FROM 
    sales_hierarchy sh
JOIN 
    most_active_customers mac ON sh.c_customer_sk = mac.c_customer_sk
WHERE 
    mac.rank <= 10
ORDER BY 
    mac.total_sales DESC
LIMIT 5
OFFSET 0;
