
WITH CustomerPurchaseData AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        cd.cd_gender,
        SUM(ws.ws_quantity) AS total_purchases,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND ca.ca_city IN (SELECT ca_city FROM customer_address WHERE ca_state = 'CA')
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, cd.cd_gender
),
TopCustomers AS (
    SELECT 
        cpd.c_customer_id,
        cpd.c_first_name,
        cpd.c_last_name,
        cpd.ca_city,
        cpd.total_purchases,
        cpd.total_spent,
        RANK() OVER (PARTITION BY cpd.ca_city ORDER BY cpd.total_spent DESC) AS city_rank
    FROM 
        CustomerPurchaseData cpd
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.ca_city,
    tc.total_purchases,
    tc.total_spent
FROM 
    TopCustomers tc
WHERE 
    tc.city_rank <= 10
ORDER BY 
    tc.ca_city, tc.total_spent DESC;
