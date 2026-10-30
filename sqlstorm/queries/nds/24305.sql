
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    INNER JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) * 1.5 FROM customer_sales)
), customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        MAX(cd.cd_marital_status) AS marital_status,
        MAX(cd.cd_gender) AS gender,
        MAX(hd.hd_income_band_sk) AS income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    cd.marital_status,
    cd.gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    high_value_customers hvc 
JOIN 
    customer_details cd ON hvc.c_customer_sk = cd.c_customer_sk 
LEFT JOIN 
    income_band ib ON cd.income_band = ib.ib_income_band_sk
WHERE 
    (ib.ib_lower_bound IS NOT NULL AND ib.ib_upper_bound IS NOT NULL) 
    OR (hvc.total_sales > 10000 AND cd.gender IS NOT NULL)
ORDER BY 
    hvc.sales_rank, hvc.c_last_name DESC
LIMIT 10 OFFSET 10;
