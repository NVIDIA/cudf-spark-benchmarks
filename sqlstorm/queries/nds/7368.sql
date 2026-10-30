
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_net_profit,
        cs.total_transactions,
        cs.avg_purchase_estimate,
        RANK() OVER (ORDER BY cs.total_net_profit DESC) AS rank
    FROM 
        CustomerSummary cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    tc.c_customer_id,
    tc.total_net_profit,
    tc.total_transactions,
    tc.avg_purchase_estimate,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM 
    TopCustomers tc
JOIN 
    customer_address ca ON tc.c_customer_id = ca.ca_address_id
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_net_profit DESC;
