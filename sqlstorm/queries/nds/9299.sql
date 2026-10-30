WITH SalesSummary AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_ext_sales_price) AS total_sales, 
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2001 AND 
        d.d_moy IN (11, 12)  
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
DemographicSummary AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(cs.cs_order_number) AS total_catalog_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_revenue
    FROM 
        customer_demographics cd
    JOIN 
        catalog_sales cs ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
FinalSummary AS (
    SELECT 
        ss.c_customer_sk,
        ss.c_first_name,
        ss.c_last_name,
        ss.total_sales,
        ss.total_orders,
        ds.total_catalog_sales,
        ds.total_catalog_revenue
    FROM 
        SalesSummary ss
    LEFT JOIN 
        DemographicSummary ds ON ss.c_customer_sk = ds.cd_demo_sk
)
SELECT 
    fs.c_customer_sk, 
    fs.c_first_name, 
    fs.c_last_name, 
    fs.total_sales, 
    fs.total_orders, 
    COALESCE(fs.total_catalog_sales, 0) AS total_catalog_sales,
    COALESCE(fs.total_catalog_revenue, 0) AS total_catalog_revenue,
    CASE 
        WHEN fs.total_sales >= 5000 THEN 'High Value'
        WHEN fs.total_sales BETWEEN 1000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    FinalSummary fs
ORDER BY 
    fs.total_sales DESC
LIMIT 100;