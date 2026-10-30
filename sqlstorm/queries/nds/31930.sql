
WITH  Sales_CTE AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_sales_price, 
        ws_quantity,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023 AND d_moy = 1) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023 AND d_moy = 12)
    UNION ALL
    SELECT 
        cs_item_sk, 
        cs_order_number, 
        cs_sales_price, 
        cs_quantity,
        cs_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_order_number) AS rn
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023 AND d_moy = 1) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023 AND d_moy = 12)
)
SELECT 
    s.ws_item_sk,
    COALESCE(SUM(s.ws_quantity), 0) AS total_quantity,
    COALESCE(SUM(s.ws_ext_sales_price), 0) AS total_sales,
    COUNT(DISTINCT s.ws_order_number) AS total_orders,
    (SELECT COUNT(DISTINCT c_customer_sk) 
     FROM customer 
     WHERE c_current_cdemo_sk IN (SELECT cd_demo_sk FROM customer_demographics WHERE cd_gender = 'M')) AS male_customers,
    (SELECT COUNT(DISTINCT c_customer_sk)
     FROM customer
     WHERE c_current_cdemo_sk IN (SELECT cd_demo_sk FROM customer_demographics WHERE cd_marital_status = 'M')) AS married_customers
FROM 
    Sales_CTE s
GROUP BY 
    s.ws_item_sk
HAVING 
    COALESCE(SUM(s.ws_ext_sales_price), 0) > (SELECT AVG(ws_ext_sales_price) FROM web_sales WHERE ws_item_sk = s.ws_item_sk)
ORDER BY 
    total_sales DESC;
