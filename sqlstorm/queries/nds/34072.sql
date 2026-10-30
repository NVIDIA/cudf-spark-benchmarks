
WITH  Sales_CTE AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ws_ship_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_ship_date_sk) AS rn
    FROM web_sales
    WHERE ws_sales_price > 0
), 
Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(s.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT s.ws_order_number) AS order_count,
        STRING_AGG(DISTINCT CONCAT(i.i_item_desc, ': ', s.ws_quantity), ', ') AS items_bought
    FROM customer c
    JOIN Sales_CTE s ON c.c_customer_sk = s.ws_item_sk
    JOIN item i ON s.ws_item_sk = i.i_item_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), 
Aggregated_Sales AS (
    SELECT 
        total_sales,
        order_count,
        NTILE(10) OVER (ORDER BY total_sales DESC) AS income_bracket
    FROM Customer_Sales
)
SELECT
    ASG.income_bracket,
    AVG(total_sales) AS average_sales,
    MAX(order_count) AS max_orders,
    SUM(CASE WHEN total_sales IS NULL THEN 1 ELSE 0 END) AS null_sales_count
FROM Aggregated_Sales ASG
GROUP BY ASG.income_bracket
ORDER BY income_bracket;
