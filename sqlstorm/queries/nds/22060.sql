
WITH  address_hierarchy AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS address_rank
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
),
demographic_summary AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
date_aggregate AS (
    SELECT 
        d_year,
        COUNT(d_date) AS total_days,
        SUM(d_dom) AS sum_dom,
        MAX(d_date) AS max_date
    FROM 
        date_dim
    WHERE 
        d_year >= 2010
    GROUP BY 
        d_year
),
sales_statistics AS (
    SELECT 
        'Store' AS sales_type,
        ss_store_sk AS store_id,
        SUM(ss_quantity) AS total_quantity,
        AVG(ss_sales_price) AS avg_sales_price
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
    UNION ALL
    SELECT 
        'Web' AS sales_type,
        ws_web_site_sk AS store_id,
        SUM(ws_quantity) AS total_quantity,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    GROUP BY 
        ws_web_site_sk
)
SELECT 
    ah.ca_street_name,
    ah.ca_city,
    ah.ca_state,
    ds.cd_gender,
    ds.demographic_count,
    ds.avg_purchase_estimate,
    ds.married_count,
    da.d_year,
    da.total_days,
    da.sum_dom,
    ss.sales_type,
    ss.total_quantity,
    ss.avg_sales_price
FROM 
    address_hierarchy ah
LEFT JOIN 
    demographic_summary ds ON ah.address_rank = ds.demographic_count % 5
INNER JOIN 
    date_aggregate da ON da.total_days > 0
FULL OUTER JOIN 
    sales_statistics ss ON ah.ca_address_sk BETWEEN ss.store_id - 10 AND ss.store_id + 10
WHERE 
    (ah.ca_state IS NOT NULL AND ss.total_quantity > 50)
    OR (ss.sales_type = 'Web' AND ss.avg_sales_price IS NOT NULL)
GROUP BY
    ah.ca_street_name,
    ah.ca_city,
    ah.ca_state,
    ds.cd_gender,
    ds.demographic_count,
    ds.avg_purchase_estimate,
    ds.married_count,
    da.d_year,
    da.total_days,
    da.sum_dom,
    ss.sales_type,
    ss.total_quantity,
    ss.avg_sales_price
ORDER BY 
    ah.ca_city, ds.cd_gender, da.d_year DESC
LIMIT 100 OFFSET 10;
