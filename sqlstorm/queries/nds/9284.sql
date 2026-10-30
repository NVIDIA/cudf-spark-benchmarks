
WITH sales_summary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_quantity) AS total_items_sold,
        SUM(ss.ss_sales_price) AS total_sales,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 3000 AND 3060
    GROUP BY 
        c.c_customer_sk
),
demographic_summary AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT c.c_current_addr_sk) AS unique_addresses
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
),
combined_summary AS (
    SELECT 
        ds.c_customer_sk,
        ds.total_items_sold,
        ds.total_sales,
        ds.avg_sales_price,
        d.customer_count,
        d.avg_purchase_estimate,
        d.unique_addresses
    FROM 
        sales_summary ds
    JOIN 
        demographic_summary d ON ds.c_customer_sk = d.customer_count
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cs.total_items_sold,
    cs.total_sales,
    cs.avg_sales_price,
    cs.customer_count,
    cs.avg_purchase_estimate,
    cs.unique_addresses
FROM 
    combined_summary cs
JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk
ORDER BY 
    cs.total_sales DESC
LIMIT 100;
