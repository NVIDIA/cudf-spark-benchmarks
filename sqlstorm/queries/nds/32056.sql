
WITH  sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS sales_rank
    FROM store_sales
    GROUP BY ss_store_sk
),
top_stores AS (
    SELECT 
        store.s_store_id,
        store.s_store_name,
        sales.total_sales,
        sales.total_transactions
    FROM store AS store
    JOIN sales_summary AS sales ON store.s_store_sk = sales.ss_store_sk
    WHERE sales.sales_rank <= 5
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        CASE 
            WHEN hd.hd_income_band_sk IS NULL THEN 'Not Specified'
            ELSE CONCAT('Income Band ', hd.hd_income_band_sk)
        END AS income_band
    FROM customer AS c
    LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics AS hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
return_summary AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT 
    top.s_store_name,
    top.total_sales,
    top.total_transactions,
    COUNT(DISTINCT ci.c_customer_id) AS unique_customers,
    STRING_AGG(DISTINCT ci.gender) AS genders,
    SUM(rs.total_returns) AS total_returns,
    SUM(rs.total_return_value) AS total_return_value,
    COUNT(CASE WHEN rs.avg_return_quantity IS NULL THEN 1 END) AS zero_return_items
FROM top_stores AS top
LEFT JOIN customer_info AS ci ON top.s_store_id = ci.c_customer_id
LEFT JOIN return_summary AS rs ON ci.c_customer_id = CAST(rs.sr_item_sk AS STRING)
GROUP BY top.s_store_id, top.s_store_name, top.total_sales, top.total_transactions
HAVING SUM(rs.total_return_value) > 0
ORDER BY total_sales DESC;
