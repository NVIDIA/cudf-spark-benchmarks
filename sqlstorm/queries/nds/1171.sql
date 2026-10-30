
WITH sales_summary AS (
    SELECT 
        s.s_store_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        AVG(ss_net_paid) AS avg_transaction_value,
        RANK() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales
    JOIN 
        store s ON store_sales.ss_store_sk = s.s_store_sk
    WHERE 
        ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023) 
    GROUP BY 
        s.s_store_sk
), 
customer_demographics_summary AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd.cd_dep_count) AS max_dependents,
        MIN(cd.cd_credit_rating) AS min_credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    ss.s_store_sk,
    ss.total_sales,
    ss.total_transactions,
    ss.avg_transaction_value,
    cd.customer_count,
    cd.avg_purchase_estimate,
    cd.max_dependents,
    cd.min_credit_rating
FROM 
    sales_summary ss
FULL OUTER JOIN 
    customer_demographics_summary cd ON ss.s_store_sk = cd.cd_demo_sk
WHERE 
    (ss.sales_rank <= 10 OR cd.customer_count IS NOT NULL)
ORDER BY 
    total_sales DESC NULLS LAST;
