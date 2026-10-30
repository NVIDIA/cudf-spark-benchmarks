
WITH  SalesCTE AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20210101 AND 20211231
), 
CustomerIncome AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
)
SELECT 
    ia.item_count,
    ci.cd_gender AS gender,
    ci.cd_marital_status AS marital_status,
    SUM(s.ws_ext_sales_price) AS total_sales,
    AVG(s.ws_quantity) AS avg_quantity,
    MAX(s.ws_sales_price) AS max_price,
    MIN(s.ws_sales_price) AS min_price,
    CASE 
        WHEN ci.hd_income_band_sk IS NULL THEN 'Unknown Income Band'
        ELSE CONCAT('Income Band: ', ci.hd_income_band_sk)
    END AS income_band_desc
FROM 
    (SELECT ws_item_sk, COUNT(*) AS item_count
     FROM SalesCTE
     WHERE rn = 1
     GROUP BY ws_item_sk) ia
JOIN 
    CustomerIncome ci ON ia.ws_item_sk = ci.c_customer_sk
JOIN 
    web_sales s ON ia.ws_item_sk = s.ws_item_sk
GROUP BY 
    ia.item_count, ci.cd_gender, ci.cd_marital_status, ci.hd_income_band_sk
HAVING 
    SUM(s.ws_ext_sales_price) > 5000
ORDER BY 
    total_sales DESC
LIMIT 10;
