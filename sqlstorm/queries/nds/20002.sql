
WITH  customer_income AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN cd.cd_credit_rating = 'Low' THEN '0-20000'
            WHEN cd.cd_credit_rating = 'Medium' THEN '20001-50000'
            WHEN cd.cd_credit_rating = 'High' THEN '50001-100000'
            ELSE 'Unknown'
        END AS income_band,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_credit_rating
),
customer_avg_sales AS (
    SELECT 
        cs_bill_customer_sk,
        AVG(cs_net_paid) AS avg_sales
    FROM 
        catalog_sales
    WHERE 
        cs_net_paid IS NOT NULL
    GROUP BY 
        cs_bill_customer_sk
),
sales_summary AS (
    SELECT 
        ci.income_band,
        COALESCE(AVG(cas.avg_sales), 0) AS avg_sales,
        SUM(ci.customer_count) AS total_customers
    FROM 
        customer_income ci
    LEFT JOIN 
        customer_avg_sales cas ON ci.cd_demo_sk = cas.cs_bill_customer_sk
    GROUP BY 
        ci.income_band
),
filtered_sales AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(ss.ss_ticket_number) AS transaction_count
    FROM 
        store_sales ss
    JOIN 
        sales_summary ss1 ON ss1.income_band LIKE '%50000%'
    WHERE 
        ss.ss_net_paid > (SELECT COALESCE(MAX(avg_sales), 0) FROM sales_summary WHERE total_customers > 50)
    GROUP BY 
        ss.ss_store_sk
)
SELECT 
    s.s_store_id,
    f.total_net_paid,
    f.transaction_count,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY f.total_net_paid DESC) AS rank
FROM 
    store s
JOIN 
    filtered_sales f ON f.ss_store_sk = s.s_store_sk
WHERE 
    f.transaction_count IS NOT NULL
ORDER BY 
    f.total_net_paid DESC, rank
LIMIT 10;
