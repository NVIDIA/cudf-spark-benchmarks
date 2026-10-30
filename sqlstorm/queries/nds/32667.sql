
WITH  sales_ranking AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
high_income_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS income_category
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' OR cd.cd_gender = 'F'
), 
sales_details AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS sold_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        MAX(ws.ws_sold_date_sk) AS last_sale_date
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    hic.c_customer_sk,
    hic.c_first_name,
    hic.c_last_name,
    hic.income_category,
    sd.sold_quantity,
    sd.total_net_profit,
    sd.total_discount,
    sr.rank
FROM 
    high_income_customers hic
LEFT JOIN 
    sales_details sd ON hic.c_customer_sk = sd.ws_item_sk
JOIN 
    sales_ranking sr ON hic.c_customer_sk = sr.ws_bill_customer_sk
WHERE 
    sd.sold_quantity IS NOT NULL
ORDER BY 
    hic.income_category, sr.rank;
