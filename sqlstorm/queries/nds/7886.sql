
WITH CustomerSpend AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_spent,
        cs.total_orders,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        CustomerSpend cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSpend)
),
CustomerAddressDetails AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
FinalReport AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.total_spent,
        hvc.total_orders,
        hvc.cd_gender,
        hvc.cd_marital_status,
        hvc.cd_education_status,
        cad.ca_city,
        cad.ca_state,
        cad.ca_country
    FROM 
        HighValueCustomers hvc
    JOIN 
        CustomerAddressDetails cad ON hvc.c_customer_sk = cad.c_customer_sk
)
SELECT 
    COUNT(*) AS high_value_customer_count,
    AVG(total_spent) AS avg_spending,
    AVG(total_orders) AS avg_orders_per_customer,
    cd_gender,
    cd_marital_status,
    ca_city,
    ca_state,
    ca_country
FROM 
    FinalReport
GROUP BY 
    cd_gender, cd_marital_status, ca_city, ca_state, ca_country
ORDER BY 
    high_value_customer_count DESC;
