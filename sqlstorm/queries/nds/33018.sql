
WITH  sales_history AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
customer_addresses AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer
    JOIN 
        customer_address ON c_current_addr_sk = ca_address_sk
    GROUP BY 
        ca_state
),
promotions AS (
    SELECT 
        p_promo_id,
        p_discount_active,
        SUM(p_cost) AS total_cost
    FROM 
        promotion
    WHERE 
        p_discount_active = 'Y'
    GROUP BY 
        p_promo_id, p_discount_active
),
customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent,
        cd.cd_gender
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
)
SELECT 
    ca.ca_state,
    COUNT(DISTINCT cs.c_customer_id) AS active_customers,
    AVG(cs.total_spent) AS average_spent,
    MAX(cs.total_spent) AS highest_spent,
    MAX(sh.total_sales) AS max_sales_in_week
FROM 
    customer_addresses ca
LEFT JOIN 
    customer_sales cs ON ca.ca_state = cs.cd_gender 
LEFT JOIN 
    sales_history sh ON cs.total_spent < sh.total_sales
WHERE 
    ca.customer_count > 50
GROUP BY 
    ca.ca_state
HAVING 
    AVG(cs.total_spent) > 100
ORDER BY 
    active_customers DESC;
