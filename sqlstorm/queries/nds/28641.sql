
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender_desc
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
OrderStatistics AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        cd.gender_desc,
        os.total_orders,
        os.total_spent,
        COALESCE(os.total_orders, 0) AS order_count,
        COALESCE(os.total_spent, 0) AS spending
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        OrderStatistics os ON cd.c_customer_sk = os.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    gender_desc,
    order_count,
    spending,
    (spending / NULLIF(order_count, 0)) AS avg_spent_per_order
FROM 
    FinalReport
ORDER BY 
    spending DESC
LIMIT 50;
