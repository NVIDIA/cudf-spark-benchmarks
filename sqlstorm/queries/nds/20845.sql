
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
), 
last_purchases AS (
    SELECT 
        c.c_customer_sk,
        MAX(ws_sold_date_sk) AS last_purchase_date
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ss.total_quantity_sold,
    ss.total_sales,
    lp.last_purchase_date,
    (CASE 
         WHEN ci.gender_rank = 1 THEN 'Top Buyer'
         ELSE 'Regular Buyer'
     END) AS buyer_status
FROM 
    customer_info ci
LEFT JOIN 
    sales_summary ss ON ci.c_customer_sk = ss.ws_item_sk
LEFT JOIN 
    last_purchases lp ON ci.c_customer_sk = lp.c_customer_sk
WHERE 
    (ss.total_sales > (SELECT AVG(total_sales) FROM sales_summary) 
     OR ci.cd_marital_status = 'S')
    AND ci.buy_potential IS NOT NULL
ORDER BY 
    ss.total_sales DESC NULLS LAST
LIMIT 10;
