
WITH  sales_cte AS (
    SELECT 
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS transaction_count,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_sold_date_sk, ss_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count,
        SUM(ss.ss_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, hd.hd_income_band_sk
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.gender,
        cs.income_band,
        cs.purchase_count,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM 
        customer_summary cs
)
SELECT 
    t.ss_item_sk AS s_product_id,
    t.total_sales,
    t.transaction_count,
    tc.gender,
    tc.income_band,
    tc.purchase_count,
    tc.total_spent
FROM 
    sales_cte t
JOIN 
    top_customers tc ON t.ss_item_sk = tc.c_customer_sk
WHERE 
    t.sales_rank <= 10 
    AND tc.purchase_count > 0
ORDER BY 
    total_sales DESC
LIMIT 100;
