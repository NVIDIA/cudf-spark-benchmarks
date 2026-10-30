
WITH sales_summary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price,
        d.d_year
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        c.c_customer_sk, d.d_year
),
demographics_analysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.total_sales) AS total_sales_by_demo,
        COUNT(DISTINCT ss.c_customer_sk) AS number_of_customers
    FROM 
        sales_summary ss
    JOIN 
        customer_demographics cd ON ss.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
warehouse_distribution AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    da.cd_gender,
    da.cd_marital_status,
    da.total_sales_by_demo,
    da.number_of_customers,
    wd.w_warehouse_id,
    wd.total_quantity_sold
FROM 
    demographics_analysis da
JOIN 
    warehouse_distribution wd ON wd.total_quantity_sold > 1000
ORDER BY 
    da.total_sales_by_demo DESC, wd.total_quantity_sold DESC
LIMIT 50;
