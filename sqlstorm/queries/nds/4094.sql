
WITH customer_info AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        (SELECT COUNT(*) 
         FROM store_sales ss 
         WHERE ss.ss_customer_sk = c.c_customer_sk
        ) AS total_purchases
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
), 
sales_summary AS (
    SELECT 
        ss.ss_item_sk, 
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(*) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY SUM(ss.ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d.d_date_sk 
                                FROM date_dim d 
                                WHERE d.d_year = 2023)
    GROUP BY 
        ss.ss_item_sk
), 
top_items AS (
    SELECT 
        ti.ss_item_sk, 
        ti.total_sales, 
        ti.total_transactions 
    FROM 
        sales_summary ti
    WHERE 
        ti.sales_rank <= 10
)
SELECT 
    ci.c_first_name, 
    ci.c_last_name, 
    ti.total_sales, 
    ti.total_transactions, 
    COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns,
    ROUND((ti.total_sales - COALESCE(SUM(sr.sr_return_amt), 0)), 2) AS net_sales
FROM 
    customer_info ci
LEFT JOIN 
    top_items ti ON EXISTS (
        SELECT 1 
        FROM store_sales ss 
        WHERE ss.ss_customer_sk = ci.c_customer_sk 
          AND ss.ss_item_sk = ti.ss_item_sk
    )
LEFT JOIN 
    store_returns sr ON ti.ss_item_sk = sr.sr_item_sk AND ci.c_customer_sk = sr.sr_customer_sk
GROUP BY 
    ci.c_first_name, 
    ci.c_last_name, 
    ti.ss_item_sk, 
    ti.total_sales, 
    ti.total_transactions
ORDER BY 
    net_sales DESC;
