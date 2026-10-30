
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_last_name) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status
    FROM 
        RankedCustomers rc
    WHERE 
        rc.gender_rank <= 10
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS number_of_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
CustomerInsights AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        sd.total_spent,
        sd.number_of_orders
    FROM 
        TopCustomers tc
    LEFT JOIN 
        SalesData sd ON tc.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    COALESCE(ci.total_spent, 0) AS total_spent,
    COALESCE(ci.number_of_orders, 0) AS number_of_orders,
    CASE 
        WHEN ci.total_spent IS NULL THEN 'No Sales'
        WHEN ci.total_spent >= 1000 THEN 'Top Buyer'
        ELSE 'Regular Buyer' 
    END AS buyer_category
FROM 
    CustomerInsights ci
WHERE 
    ci.total_spent > (SELECT AVG(total_spent) FROM SalesData)
ORDER BY 
    ci.total_spent DESC;

