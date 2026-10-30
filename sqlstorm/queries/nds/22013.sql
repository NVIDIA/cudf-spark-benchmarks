
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(*) AS purchase_count,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS rank_spend
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_bill_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_month,
        cd.cd_marital_status,
        cd.cd_gender,
        CASE
            WHEN cd.cd_gender = 'M' AND cd.cd_marital_status = 'M' THEN 'Married Man'
            WHEN cd.cd_gender = 'F' AND cd.cd_marital_status = 'M' THEN 'Married Woman'
            WHEN cd.cd_gender = 'M' AND cd.cd_marital_status = 'S' THEN 'Single Man'
            WHEN cd.cd_gender = 'F' AND cd.cd_marital_status = 'S' THEN 'Single Woman'
            ELSE 'Other'
        END AS marital_gender_group
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        (SELECT COUNT(*) FROM customer WHERE c_birth_month IS NULL AND c_current_cdemo_sk IS NOT NULL) > 0
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.marital_gender_group,
    COALESCE(rs.total_spent, 0) AS total_spent,
    COALESCE(rs.purchase_count, 0) AS purchase_count
FROM 
    customer_info ci
LEFT JOIN 
    ranked_sales rs ON ci.c_customer_sk = rs.ws_bill_customer_sk
WHERE 
    ci.c_first_name IS NOT NULL 
    AND (rs.purchase_count > 5 OR rs.rank_spend IS NULL)
ORDER BY 
    total_spent DESC, 
    ci.c_birth_month,
    CASE WHEN ci.marital_gender_group = 'Married Man' THEN 1
         WHEN ci.marital_gender_group = 'Married Woman' THEN 2
         WHEN ci.marital_gender_group = 'Single Man' THEN 3
         WHEN ci.marital_gender_group = 'Single Woman' THEN 4
         ELSE 5 END;
