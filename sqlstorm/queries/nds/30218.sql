
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS row_num
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-01-01')
), MonthlyTotals AS (
    SELECT 
        DATE_TRUNC('month', d_date) AS sales_month,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_item_sk) AS total_items_sold
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        DATE_TRUNC('month', d_date)
), HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        SUM(ws_ext_sales_price) > 1000
)
SELECT 
    addr.ca_city,
    SUM(ws.ws_ext_sales_price) AS city_sales,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    MAX(ws.ws_quantity) AS max_quantity_sold,
    COUNT(DISTINCT ws.ws_order_number) AS orders_count,
    (SELECT MAX(total_spent) FROM HighValueCustomers) AS max_customer_spending
FROM 
    web_sales ws
LEFT JOIN 
    customer_address addr ON ws.ws_bill_addr_sk = addr.ca_address_sk
JOIN 
    MonthlyTotals mt ON mt.total_sales > 5000
WHERE 
    addr.ca_state = 'NY' AND
    (ws.ws_sales_price IS NOT NULL OR ws.ws_quantity IS NOT NULL)
GROUP BY 
    addr.ca_city
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 10
ORDER BY 
    city_sales DESC
LIMIT 5;
