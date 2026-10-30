
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        a.ca_city,
        a.ca_state,
        d.d_date AS birth_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON c.c_birth_day = d.d_dom AND c.c_birth_month = d.d_moy
    WHERE 
        cd.cd_gender = 'F' 
        AND a.ca_state IN ('CA', 'NY', 'TX') 
        AND cd.cd_education_status LIKE '%Masters%'
),
RecentPurchases AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date >= CURRENT_DATE - INTERVAL '1 year')
    GROUP BY 
        ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.birth_date,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        rp.total_orders,
        rp.total_spent
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        RecentPurchases rp ON ci.c_customer_sk = rp.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    birth_date,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    COALESCE(total_orders, 0) AS total_orders,
    COALESCE(total_spent, 0) AS total_spent,
    CASE 
        WHEN COALESCE(total_spent, 0) > 5000 THEN 'High Value'
        WHEN COALESCE(total_spent, 0) BETWEEN 1000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    FinalReport
LIMIT 100;
