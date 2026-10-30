
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        SUM(ws.ws_quantity) AS total_items_ordered,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
HighSpenders AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_orders,
        cs.total_spent,
        CASE 
            WHEN cs.total_spent > 1000 THEN 'VIP'
            WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Regular'
            ELSE 'Casual'
        END AS customer_type
    FROM 
        CustomerStats cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_orders > 0
),
ReturnStats AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_returned,
        COUNT(*) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
FinalStats AS (
    SELECT 
        hs.c_customer_sk,
        hs.c_first_name,
        hs.c_last_name,
        hs.total_orders,
        hs.total_spent,
        hs.customer_type,
        COALESCE(rs.total_returned, 0) AS total_returned,
        COALESCE(rs.total_returns, 0) AS total_returns,
        hs.total_spent - COALESCE(rs.total_returned, 0) AS net_spending
    FROM 
        HighSpenders hs
    LEFT JOIN 
        ReturnStats rs ON hs.c_customer_sk = rs.sr_customer_sk
)

SELECT 
    c.c_first_name,
    c.c_last_name,
    fs.total_orders,
    fs.total_spent,
    fs.customer_type,
    fs.total_returned,
    fs.total_returns,
    fs.net_spending
FROM 
    FinalStats fs
JOIN 
    customer c ON fs.c_customer_sk = c.c_customer_sk
WHERE 
    fs.net_spending > 0 
ORDER BY 
    fs.net_spending DESC;
