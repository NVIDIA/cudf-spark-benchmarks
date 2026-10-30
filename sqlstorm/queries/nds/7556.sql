
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        COUNT(DISTINCT ws_ship_date_sk) AS unique_ship_dates
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        ws_bill_customer_sk
),
demographics_summary AS (
    SELECT 
        cd_demo_sk AS customer_sk,
        COUNT(hd_demo_sk) AS household_count,
        MAX(hd_vehicle_count) AS max_vehicle_count,
        SUM(cd_dep_count) AS total_dependent_count
    FROM 
        customer_demographics 
    INNER JOIN 
        household_demographics ON cd_demo_sk = hd_demo_sk
    GROUP BY 
        cd_demo_sk
),
combined_summary AS (
    SELECT 
        cs.customer_sk,
        cs.total_sales,
        cs.order_count,
        cs.unique_ship_dates,
        ds.household_count,
        ds.max_vehicle_count,
        ds.total_dependent_count
    FROM 
        sales_summary cs
    LEFT JOIN 
        demographics_summary ds ON cs.customer_sk = ds.customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cs.total_sales,
    cs.order_count,
    cs.unique_ship_dates,
    ds.household_count,
    ds.max_vehicle_count,
    ds.total_dependent_count
FROM 
    customer c
JOIN 
    combined_summary cs ON c.c_customer_sk = cs.customer_sk
JOIN 
    demographics_summary ds ON cs.customer_sk = ds.customer_sk
WHERE 
    cs.total_sales > 1000
ORDER BY 
    cs.total_sales DESC
LIMIT 50;
