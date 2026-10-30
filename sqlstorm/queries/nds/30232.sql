WITH  sales_summary AS (
    SELECT
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rn
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
filtered_sales AS (
    SELECT 
        ss.customer_sk,
        ss.total_sales,
        ss.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        addr.ca_city,
        addr.ca_state,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender, cd.cd_marital_status ORDER BY ss.total_sales DESC) AS sales_rank
    FROM sales_summary ss
    JOIN customer c ON c.c_customer_sk = ss.customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address addr ON c.c_current_addr_sk = addr.ca_address_sk
    WHERE ss.total_sales > (
        SELECT AVG(total_sales) FROM sales_summary
    )
)
SELECT
    fs.customer_sk,
    fs.total_sales,
    fs.order_count,
    fs.cd_gender,
    fs.cd_marital_status,
    fs.ca_city,
    fs.ca_state,
    CASE 
        WHEN fs.sales_rank IS NULL THEN 'Unranked'
        ELSE CAST(fs.sales_rank AS STRING)
    END AS sales_rank_category
FROM filtered_sales fs
WHERE fs.order_count > 5
ORDER BY fs.total_sales DESC;