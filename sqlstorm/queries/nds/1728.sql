WITH ranked_sales AS (
    SELECT 
        cs_bill_customer_sk,
        SUM(cs_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY cs_bill_customer_sk ORDER BY SUM(cs_net_profit) DESC) AS rank
    FROM catalog_sales
    WHERE cs_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2001 
          AND d_moy IN (1, 2, 3)  
    )
    GROUP BY cs_bill_customer_sk
),

high_profit_customers AS (
    SELECT c_customer_sk, 
           c_first_name, 
           c_last_name, 
           cd_gender, 
           cd_marital_status, 
           cd_purchase_estimate
    FROM customer c
    INNER JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c_customer_sk IN (
        SELECT cs_bill_customer_sk 
        FROM ranked_sales 
        WHERE rank <= 10
    )
)

SELECT 
    hpc.c_first_name,
    hpc.c_last_name,
    hpc.cd_gender,
    hpc.cd_marital_status,
    hpc.cd_purchase_estimate,
    COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
    COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales
FROM high_profit_customers hpc
LEFT JOIN web_sales ws ON hpc.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN store_sales ss ON hpc.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    hpc.c_first_name, 
    hpc.c_last_name, 
    hpc.cd_gender, 
    hpc.cd_marital_status, 
    hpc.cd_purchase_estimate
HAVING 
    (COALESCE(SUM(ws.ws_net_paid), 0) > 1000 OR COALESCE(SUM(ss.ss_net_paid), 0) > 1000)
ORDER BY total_web_sales DESC, total_store_sales DESC;