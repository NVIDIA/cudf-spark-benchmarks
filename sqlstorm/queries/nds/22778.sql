
WITH  CustomerOrders AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        COUNT(ss.ss_ticket_number) AS total_orders,
        SUM(ss.ss_sales_price) AS total_spent,
        ROW_NUMBER() OVER(PARTITION BY c.c_customer_sk ORDER BY COUNT(ss.ss_ticket_number) DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
FilteredCustomers AS (
    SELECT 
        co.c_customer_id,
        co.total_orders,
        co.total_spent,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        CustomerOrders co
    JOIN 
        customer_demographics cd ON co.c_customer_sk = cd.cd_demo_sk
    WHERE 
        co.total_orders > 5 AND 
        cd.cd_marital_status = 'M' AND 
        (cd.cd_gender = 'M' OR cd.cd_gender IS NULL)
),
MaxSpend AS (
    SELECT 
        f.c_customer_id,
        f.total_spent,
        DENSE_RANK() OVER (ORDER BY f.total_spent DESC) AS spend_rank
    FROM 
        FilteredCustomers f
)
SELECT 
    a.ca_country,
    MAX(m.total_spent) AS max_spent,
    MIN(m.total_spent) AS min_spent,
    AVG(m.total_spent) AS avg_spent
FROM 
    MaxSpend m
LEFT JOIN 
    customer c ON m.c_customer_id = c.c_customer_id
LEFT JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
GROUP BY 
    a.ca_country
HAVING 
    MAX(m.total_spent) IS NOT NULL
ORDER BY 
    a.ca_country
LIMIT 100;
