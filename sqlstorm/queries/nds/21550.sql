
WITH  Customer_Stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_gender, 'M') AS gender,
        COALESCE(cd.cd_marital_status, 'S') AS marital_status,
        COALESCE(SUM(ws.ws_quantity) FILTER(WHERE ws.ws_ship_date_sk IS NOT NULL), 0) AS total_quantity,
        COALESCE(SUM(ws.ws_net_paid) FILTER(WHERE ws.ws_ship_date_sk IS NOT NULL), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
Return_Stats AS (
    SELECT
        sr.sr_customer_sk,
        COUNT(sr.sr_ticket_number) AS return_count,
        SUM(sr.sr_return_amt) AS total_returned
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
),
Combined_Stats AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.gender,
        cs.marital_status,
        cs.total_quantity,
        cs.total_spent,
        COALESCE(rs.return_count, 0) AS return_count,
        COALESCE(rs.total_returned, 0) AS total_returned,
        CASE 
            WHEN cs.total_spent = 0 THEN NULL 
            ELSE (rs.total_returned / cs.total_spent) * 100 
        END AS return_rate
    FROM 
        Customer_Stats cs
    LEFT JOIN 
        Return_Stats rs ON cs.c_customer_sk = rs.sr_customer_sk
),
Ranked_Customers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY gender ORDER BY total_spent DESC) AS rank_spent
    FROM 
        Combined_Stats
)
SELECT 
    *,
    CASE 
        WHEN total_spent > 500 THEN 'High Value'
        WHEN total_spent BETWEEN 100 AND 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment,
    CASE 
        WHEN return_rate IS NOT NULL 
            AND return_rate > 0 THEN 'Frequent Returner'
        ELSE 'Rare Returner'
    END AS return_behavior
FROM 
    Ranked_Customers
WHERE 
    (rank_spent <= 10 OR (gender = 'F' AND total_spent > 300))
ORDER BY 
    gender, return_rate DESC NULLS LAST;
