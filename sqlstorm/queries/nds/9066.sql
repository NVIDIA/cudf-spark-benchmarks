WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2458865 AND 2459300 
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
TopCustomers AS (
    SELECT 
        rc.c_customer_id,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        rc.total_profit,
        rc.order_count
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rnk <= 10  
)
SELECT 
    a.ca_city,
    COUNT(DISTINCT tc.c_customer_id) AS num_top_customers,
    AVG(tc.total_profit) AS avg_profit
FROM 
    customer_address a
JOIN 
    customer c ON a.ca_address_sk = c.c_current_addr_sk
JOIN 
    TopCustomers tc ON c.c_customer_id = tc.c_customer_id
GROUP BY 
    a.ca_city
ORDER BY 
    num_top_customers DESC
LIMIT 5;