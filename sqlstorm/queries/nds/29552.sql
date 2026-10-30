
WITH Customer_Overview AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchase_count,
        SUM(ss.ss_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, ca.ca_city, ca.ca_state, ca.ca_country
),
Sales_Analysis AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        SUM(cs.cs_net_profit) AS total_profit
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.cs_item_sk
),
Top_Customers AS (
    SELECT 
        co.full_name,
        co.marital_status,
        co.ca_city,
        co.total_purchase_count,
        co.total_spent,
        ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS rank
    FROM 
        Customer_Overview co
)
SELECT 
    tc.full_name,
    tc.marital_status,
    tc.ca_city,
    tc.total_purchase_count,
    tc.total_spent,
    sa.total_quantity_sold AS item_quantity,
    sa.total_profit
FROM 
    Top_Customers tc
JOIN 
    Sales_Analysis sa ON tc.total_purchase_count > 5
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_spent DESC, tc.full_name;
