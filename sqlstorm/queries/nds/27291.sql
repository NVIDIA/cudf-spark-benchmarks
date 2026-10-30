
WITH CTE_Concat_Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CTE_Sales_Stats AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CTE_Most_Valuable_Customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.full_name,
        ci.address,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ss.total_spent,
        ss.total_orders
    FROM 
        CTE_Concat_Customer_Info ci
    JOIN 
        CTE_Sales_Stats ss ON ci.c_customer_sk = ss.customer_sk
    WHERE 
        ss.total_spent > (SELECT AVG(total_spent) FROM CTE_Sales_Stats)
)
SELECT 
    mv.full_name,
    mv.address,
    mv.cd_gender,
    mv.cd_marital_status,
    mv.cd_education_status,
    mv.cd_purchase_estimate,
    mv.total_spent,
    mv.total_orders,
    (CASE 
        WHEN mv.cd_gender = 'M' THEN 'Male'
        WHEN mv.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END) AS gender_full,
    (CASE 
        WHEN mv.total_orders > 10 THEN 'Loyal Customer'
        ELSE 'New/Occasional Customer'
    END) AS customer_status
FROM 
    CTE_Most_Valuable_Customers mv
ORDER BY 
    mv.total_spent DESC;
