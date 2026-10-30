
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name, 
        c.c_last_name, 
        ca.ca_city, 
        ca.ca_state, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        SUM(ws.ws_quantity) AS total_quantities,
        SUM(ws.ws_net_paid) AS total_spending
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        ca.ca_city, 
        ca.ca_state, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_purchase_estimate
),
HighSpenders AS (
    SELECT 
        c.*, 
        RANK() OVER (PARTITION BY c.ca_state ORDER BY c.total_spending DESC) as spending_rank
    FROM 
        CustomerData c
    WHERE 
        c.total_spending > (SELECT AVG(total_spending) FROM CustomerData)
)
SELECT 
    hs.c_first_name, 
    hs.c_last_name, 
    hs.ca_city, 
    hs.ca_state, 
    hs.cd_gender, 
    hs.cd_marital_status, 
    hs.cd_purchase_estimate, 
    hs.total_quantities, 
    hs.total_spending
FROM 
    HighSpenders hs
WHERE 
    hs.spending_rank <= 10
ORDER BY 
    hs.ca_state, 
    hs.total_spending DESC;
