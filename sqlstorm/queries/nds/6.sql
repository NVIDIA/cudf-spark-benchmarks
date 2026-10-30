
WITH RankedWebSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rn
    FROM 
        web_sales ws 
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk 
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
),
HighValueReturns AS (
    SELECT 
        wr.wr_order_number, 
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr 
    JOIN 
        customer c ON wr.wr_returning_customer_sk = c.c_customer_sk 
    WHERE 
        c.c_last_name LIKE 'S%' 
    GROUP BY 
        wr.wr_order_number
    HAVING 
        SUM(wr.wr_return_amt) > 100
),
SalesWithAddress AS (
    SELECT 
        ws.ws_order_number,
        c.c_first_name || ' ' || c.c_last_name AS customer_name,
        ca.ca_city,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state = 'CA'
    GROUP BY 
        ws.ws_order_number, c.c_first_name, c.c_last_name, ca.ca_city
)
SELECT 
    sw.ws_order_number,
    sw.customer_name,
    sw.ca_city,
    COALESCE(hl.total_return_amount, 0) AS total_return_amount,
    sw.total_sales,
    CASE 
        WHEN sw.total_sales > 500 THEN 'High Value' 
        ELSE 'Regular' 
    END AS sales_category
FROM 
    SalesWithAddress sw
LEFT JOIN 
    HighValueReturns hl ON sw.ws_order_number = hl.wr_order_number
WHERE 
    (sw.total_sales > 200 OR (hl.total_return_amount > 0 AND hl.total_return_amount IS NOT NULL))
ORDER BY 
    sw.total_sales DESC;
