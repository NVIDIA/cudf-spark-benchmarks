
WITH SalesData AS (
    SELECT 
        ws_order_number, 
        ws_item_sk, 
        ws_quantity, 
        ws_sales_price, 
        ws_ext_discount_amt, 
        ws_ext_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws_order_number ORDER BY ws_sales_price DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2450671
),
CustomerData AS (
    SELECT 
        c_customer_sk, 
        c_first_name || ' ' || c_last_name AS full_name, 
        cd_gender, 
        cd_marital_status, 
        cd_purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    SUM(sd.ws_quantity) AS total_quantity_sold,
    SUM(sd.ws_ext_sales_price) AS total_sales_amount,
    AVG(sd.ws_ext_discount_amt) AS average_discount,
    COUNT(DISTINCT sd.ws_order_number) AS total_orders,
    (CASE 
        WHEN cd.cd_marital_status = 'M' THEN 'Married'
        WHEN cd.cd_marital_status = 'S' THEN 'Single'
        ELSE 'Other'
    END) AS marital_status_description
FROM SalesData sd
JOIN CustomerData cd ON sd.ws_item_sk = cd.c_customer_sk
WHERE sd.sales_rank = 1
GROUP BY cd.full_name, cd.cd_gender, cd.cd_marital_status
HAVING SUM(sd.ws_ext_sales_price) > 1000
ORDER BY total_sales_amount DESC
LIMIT 10;
