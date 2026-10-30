
WITH RankedCustomers AS (
    SELECT 
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS purchase_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND d.d_year = 2022
    GROUP BY 
        full_name, purchase_date, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
CustomerSummary AS (
    SELECT 
        full_name,
        DATE_TRUNC('month', purchase_date) AS month,
        SUM(total_orders) AS total_orders_per_month,
        SUM(total_spent) AS total_spent_per_month
    FROM 
        RankedCustomers
    GROUP BY 
        full_name, month
)
SELECT 
    full_name, 
    month, 
    total_orders_per_month, 
    total_spent_per_month,
    CASE 
        WHEN total_spent_per_month >= 1000 THEN 'High'
        WHEN total_spent_per_month >= 500 THEN 'Medium'
        ELSE 'Low'
    END AS spending_level
FROM 
    CustomerSummary
ORDER BY 
    month, total_spent_per_month DESC;
