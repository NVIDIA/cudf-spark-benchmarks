
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Non-Binary/Other'
        END AS gender,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_purchased
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
GenderSales AS (
    SELECT 
        gender, 
        SUM(total_sales) AS total_sales_by_gender,
        SUM(transaction_count) AS total_transactions_by_gender,
        SUM(distinct_items_purchased) AS total_distinct_items_by_gender
    FROM 
        CustomerSales
    GROUP BY 
        gender
),
SalesRanked AS (
    SELECT 
        gender,
        total_sales_by_gender,
        total_transactions_by_gender,
        total_distinct_items_by_gender,
        RANK() OVER (ORDER BY total_sales_by_gender DESC) AS sales_rank
    FROM 
        GenderSales
)
SELECT 
    gender,
    total_sales_by_gender,
    total_transactions_by_gender,
    total_distinct_items_by_gender,
    sales_rank
FROM 
    SalesRanked
ORDER BY 
    sales_rank;
