
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
Customer_Demographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate,
        ib.ib_income_band_sk, 
        ib.ib_lower_bound, 
        ib.ib_upper_bound,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
Sales_Analysis AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.ib_lower_bound,
        cd.ib_upper_bound
    FROM 
        Customer_Sales cs
    JOIN Customer_Demographics cd ON cs.c_customer_sk = cd.cd_demo_sk 
    WHERE
        (cs.total_web_sales > (SELECT AVG(total_web_sales) FROM Customer_Sales) OR 
         cs.total_catalog_sales > (SELECT AVG(total_catalog_sales) FROM Customer_Sales))
)
SELECT 
    sa.c_first_name,
    sa.c_last_name,
    sa.total_web_sales,
    sa.total_catalog_sales,
    sa.total_store_sales,
    sa.cd_gender,
    sa.cd_marital_status,
    CONCAT('Income Range: ', sa.ib_lower_bound, ' - ', sa.ib_upper_bound) AS income_range
FROM 
    Sales_Analysis sa
WHERE
    sa.cd_gender = 'F' AND 
    (sa.cd_marital_status = 'S' OR sa.cd_marital_status = 'M')
ORDER BY 
    sa.total_web_sales DESC
LIMIT 100;
