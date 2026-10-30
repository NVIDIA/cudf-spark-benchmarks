
WITH Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        COALESCE(cd.cd_dep_count, 0) AS dependent_count,
        COALESCE(cd.cd_dep_employed_count, 0) AS employed_dependents,
        COALESCE(cd.cd_dep_college_count, 0) AS college_dependents
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Sales_Info AS (
    SELECT 
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
Combined_Info AS (
    SELECT
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_marital_status,
        ci.cd_gender,
        ci.cd_credit_rating,
        ci.cd_purchase_estimate,
        ci.dependent_count,
        ci.employed_dependents,
        ci.college_dependents,
        si.total_sales,
        si.order_count,
        si.total_profit
    FROM 
        Customer_Info ci
    LEFT JOIN 
        Sales_Info si ON ci.c_customer_sk = si.customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_marital_status,
    cd_gender,
    cd_credit_rating,
    cd_purchase_estimate,
    dependent_count,
    employed_dependents,
    college_dependents,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(order_count, 0) AS order_count,
    COALESCE(total_profit, 0) AS total_profit,
    CASE 
        WHEN total_sales > 10000 THEN 'High Value Customer' 
        WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value Customer' 
        ELSE 'Low Value Customer' 
    END AS customer_value_category
FROM 
    Combined_Info
ORDER BY 
    total_sales DESC;
