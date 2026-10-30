
WITH CustomerPurchaseDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_web_page_sk) AS distinct_web_pages_visited
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, full_name, ca.ca_city, cd.cd_marital_status
),
PurchaseStats AS (
    SELECT 
        full_name,
        ca_city,
        cd_marital_status,
        total_orders, 
        total_spent,
        DENSE_RANK() OVER (PARTITION BY ca_city ORDER BY total_spent DESC) AS spending_rank
    FROM 
        CustomerPurchaseDetails
)
SELECT 
    full_name,
    ca_city,
    cd_marital_status,
    total_orders,
    total_spent,
    spending_rank
FROM 
    PurchaseStats
WHERE 
    total_orders > 5
    AND spending_rank <= 10
ORDER BY 
    ca_city, spending_rank;
