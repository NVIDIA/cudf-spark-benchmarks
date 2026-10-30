
WITH  customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_orders,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank_by_gender
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        (SELECT ws_bill_customer_sk, SUM(ws_ext_sales_price) AS ws_ext_sales_price 
         FROM web_sales GROUP BY ws_bill_customer_sk) ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        (SELECT ss_customer_sk, SUM(ss_ext_sales_price) AS ss_ext_sales_price, COUNT(ss_ticket_number) AS ss_ticket_number 
         FROM store_sales GROUP BY ss_customer_sk) ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL 
        AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
ranked_customers AS (
    SELECT *,
           CASE 
               WHEN total_orders = 0 THEN 'No Purchases'
               WHEN total_orders < 5 THEN 'Few Purchases'
               ELSE 'Frequent Purchaser'
           END AS purchase_frequency
    FROM 
        customer_stats
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.cd_gender,
    r.cd_marital_status,
    COALESCE(r.total_spent, 0) AS total_spent,
    r.total_orders,
    r.rank_by_gender,
    r.purchase_frequency,
    (SELECT AVG(total_spent) FROM ranked_customers) AS avg_spent_in_segment,
    CASE 
        WHEN AVG(r.total_spent) OVER (PARTITION BY r.cd_marital_status) IS NULL 
        THEN 'No Data Available'
        ELSE 'Data Available'
    END AS status
FROM 
    ranked_customers r
FULL OUTER JOIN 
    (SELECT DISTINCT ca_state FROM customer_address WHERE ca_country = 'United States') ca ON r.cd_marital_status = COALESCE(r.cd_marital_status, '')
WHERE 
    ca.ca_state IS NOT NULL
ORDER BY 
    r.rank_by_gender, total_spent DESC
LIMIT 100;
