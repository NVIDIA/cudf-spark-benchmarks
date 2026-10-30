
WITH ranked_sales AS (
    SELECT 
        s.s_store_id,
        s.s_store_name,
        SUM(sd.ss_sales_price) AS total_sales,
        COUNT(sd.ss_ticket_number) AS total_transactions,
        RANK() OVER (PARTITION BY s.s_store_id ORDER BY SUM(sd.ss_sales_price) DESC) AS sales_rank
    FROM 
        store AS s
    JOIN 
        store_sales AS sd ON s.s_store_sk = sd.ss_store_sk
    WHERE 
        s.s_state = 'NY' AND sd.ss_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY 
        s.s_store_id, s.s_store_name
    HAVING 
        SUM(sd.ss_sales_price) > (SELECT AVG(ss_sales_price) FROM store_sales WHERE ss_sold_date_sk BETWEEN 2450000 AND 2450600)
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
        COALESCE(SUM(ss.ss_sales_price), 0) AS total_spent
    FROM 
        customer AS c
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' AND 
        cd.cd_gender = 'F'
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ci.c_customer_id,
    ci.transaction_count,
    ci.total_spent,
    COALESCE(rs.total_sales, 0) AS store_sales,
    (ci.total_spent / NULLIF(ci.transaction_count, 0)) AS avg_spent_per_transaction,
    c_length_cd AS credit_rating
FROM 
    customer_info AS ci
LEFT JOIN 
    (SELECT 
        c_customer_id, 
        MAX(cd_credit_rating) AS c_length_cd 
     FROM 
        customer AS c 
     JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
     GROUP BY 
        c_customer_id) AS cr ON ci.c_customer_id = cr.c_customer_id
LEFT JOIN 
    ranked_sales AS rs ON ci.transaction_count = rs.total_transactions
WHERE 
    ci.transaction_count > 5
ORDER BY 
    ci.total_spent DESC;
