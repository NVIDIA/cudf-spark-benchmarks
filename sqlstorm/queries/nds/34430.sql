
WITH  sales_cte AS (
    SELECT 
        w.w_warehouse_id AS warehouse_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(ws.ws_sales_price) DESC) AS rn
    FROM 
        warehouse w
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
    HAVING 
        SUM(ws.ws_sales_price) IS NOT NULL
), 
demographics_cte AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
), 
sales_summary AS (
    SELECT 
        s.warehouse_id,
        s.total_sales,
        s.order_count,
        d.cd_gender,
        d.cd_marital_status,
        d.hd_income_band_sk,
        DENSE_RANK() OVER (PARTITION BY d.hd_income_band_sk ORDER BY s.total_sales DESC) AS income_rank
    FROM 
        sales_cte s
    JOIN 
        demographics_cte d ON s.rn = 1
)
SELECT 
    warehouse_id,
    total_sales,
    order_count,
    cd_gender,
    cd_marital_status,
    hd_income_band_sk,
    income_rank
FROM 
    sales_summary
WHERE 
    (cd_gender = 'F' AND order_count > 10) 
    OR (cd_marital_status = 'M' AND total_sales > 1000)
ORDER BY 
    total_sales DESC
LIMIT 100;
