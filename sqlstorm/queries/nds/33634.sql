WITH  PurchaseDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ss.ss_net_paid) DESC) AS rank
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 1 AND 1000 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        total_spent,
        purchase_count
    FROM 
        PurchaseDetails
    WHERE 
        rank <= 10
),
CustomerWithDemo AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_spent,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        TopCustomers tc
    LEFT JOIN 
        customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
),
CustomerLocation AS (
    SELECT 
        cud.*,
        ca.ca_city,
        ca.ca_state,
        COALESCE(NULLIF(ca.ca_zip, ''), 'ZIP NOT PROVIDED') AS postal_code
    FROM 
        CustomerWithDemo cud
    JOIN 
        customer_address ca ON cud.c_customer_sk = ca.ca_address_sk
)
SELECT 
    cl.c_first_name,
    cl.c_last_name,
    cl.total_spent,
    cl.cd_gender,
    cl.cd_marital_status,
    cl.ca_city,
    cl.ca_state,
    cl.postal_code,
    DENSE_RANK() OVER (ORDER BY cl.total_spent DESC) AS spending_rank
FROM 
    CustomerLocation cl
WHERE 
    cl.cd_gender = 'F'
    AND cl.total_spent > (SELECT AVG(total_spent) FROM TopCustomers)
ORDER BY 
    spending_rank;