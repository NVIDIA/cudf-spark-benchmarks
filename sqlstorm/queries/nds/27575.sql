
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
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
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
), FilteredCustomers AS (
    SELECT 
        rc.*, 
        DENSE_RANK() OVER (PARTITION BY rc.cd_gender ORDER BY rc.total_spent DESC) AS rank_by_gender
    FROM 
        RankedCustomers rc
)
SELECT 
    fc.full_name, 
    fc.cd_gender, 
    fc.cd_marital_status, 
    fc.cd_education_status, 
    fc.total_orders, 
    fc.total_spent
FROM 
    FilteredCustomers fc
WHERE 
    fc.rank_by_gender <= 10
ORDER BY 
    fc.cd_gender, 
    fc.total_spent DESC;
