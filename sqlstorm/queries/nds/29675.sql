
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY COUNT(DISTINCT ws.ws_order_number) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
FilteredCustomers AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        total_orders,
        total_spent
    FROM 
        RankedCustomers
    WHERE 
        gender_rank <= 5
)
SELECT 
    cd_gender,
    cd_marital_status,
    cd_education_status,
    COUNT(full_name) AS customer_count,
    AVG(total_orders) AS avg_orders,
    AVG(total_spent) AS avg_spent,
    SUM(total_spent) AS total_revenue
FROM 
    FilteredCustomers
GROUP BY 
    cd_gender, cd_marital_status, cd_education_status
ORDER BY 
    total_revenue DESC;
