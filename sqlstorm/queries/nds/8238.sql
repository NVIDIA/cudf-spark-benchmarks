
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_ext_sales_price) AS avg_sales_price,
        COUNT(ws_order_number) AS order_count,
        d.d_year,
        c.c_birth_year
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        ws_bill_customer_sk, d.d_year, c.c_birth_year
),
demographics_summary AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd.cd_dep_count) AS max_dependencies,
        MIN(cd.cd_dep_count) AS min_dependencies
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    ss.ws_bill_customer_sk,
    ss.total_sales,
    ss.avg_sales_price,
    ss.order_count,
    ds.customer_count,
    ds.avg_purchase_estimate,
    ds.max_dependencies,
    ds.min_dependencies,
    ss.d_year,
    ss.c_birth_year
FROM 
    sales_summary ss
JOIN 
    demographics_summary ds ON ss.ws_bill_customer_sk = ds.cd_demo_sk
WHERE 
    ss.total_sales > 1000 AND
    ds.customer_count > 5
ORDER BY 
    ss.total_sales DESC, ds.customer_count ASC
LIMIT 100;
