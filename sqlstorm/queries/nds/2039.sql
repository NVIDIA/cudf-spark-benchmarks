
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id AS customer_id,
        cs.total_orders,
        cs.total_profit,
        DENSE_RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
    FROM 
        CustomerStats cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_profit > 5000
),
TopStates AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer c
    INNER JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_state
    HAVING 
        COUNT(DISTINCT c.c_customer_id) > 10
)
SELECT 
    hvc.customer_id,
    hvc.total_orders,
    hvc.total_profit,
    ts.ca_state,
    ts.customer_count
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    TopStates ts ON ts.ca_state IN (
        SELECT ca.ca_state 
        FROM customer c 
        INNER JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        WHERE ca.ca_state IS NOT NULL
    )
WHERE 
    hvc.profit_rank <= 10 
ORDER BY 
    hvc.total_profit DESC, hvc.customer_id;
