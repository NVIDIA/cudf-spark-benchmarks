WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales_value,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
),
ineligible_customers AS (
    SELECT 
        c_customer_sk
    FROM 
        customer 
    WHERE 
        c_last_review_date_sk IS NULL 
        OR (c_birth_year IS NOT NULL AND (EXTRACT(YEAR FROM cast('2002-10-01' as date)) - c_birth_year) < 18)
),
eligible_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        cs.total_sales_value,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS item_rank
    FROM 
        web_sales ws
        LEFT JOIN sales_summary cs ON ws.ws_item_sk = cs.ws_item_sk
    WHERE 
        cs.total_quantity IS NOT NULL 
        AND ws.ws_bill_customer_sk NOT IN (SELECT c_customer_sk FROM ineligible_customers)
)
SELECT 
    es.ws_item_sk,
    SUM(es.ws_quantity) AS final_quantity,
    AVG(es.ws_sales_price) AS avg_price,
    MAX(es.total_sales_value) AS max_sales_value,
    MIN(CASE 
            WHEN es.item_rank = 1 THEN 'Top Product'
            ELSE 'Regular Product'
        END) AS product_status
FROM 
    eligible_sales es
GROUP BY 
    es.ws_item_sk
HAVING 
    SUM(es.ws_quantity) > 1000 OR 
    AVG(es.ws_sales_price) < 10.00
ORDER BY 
    final_quantity DESC, 
    max_sales_value ASC 
LIMIT 10;