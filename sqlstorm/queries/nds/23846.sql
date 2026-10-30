
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSales)
),
StoreWebReturns AS (
    SELECT
        swr.wr_item_sk,
        SUM(swr.wr_return_quantity) AS total_returned
    FROM
        web_returns swr 
    GROUP BY 
        swr.wr_item_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT sales.c_customer_sk) AS num_customers,
    SUM(r.total_returned) AS total_returns,
    AVG(sales.total_spent) AS average_spent_per_customer
FROM    
    customer_address ca
LEFT JOIN 
    web_sales ws ON ws.ws_ship_addr_sk = ca.ca_address_sk
JOIN 
    CustomerSales sales ON sales.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    HighSpenders hp ON hp.c_customer_sk = sales.c_customer_sk
LEFT JOIN 
    StoreWebReturns r ON r.wr_item_sk = ws.ws_item_sk
WHERE 
    ca.ca_state IS NOT NULL 
    AND ca.ca_city IS NOT NULL 
    AND EXISTS (SELECT 1 FROM RankedSales rs WHERE rs.ws_item_sk = ws.ws_item_sk AND rs.price_rank = 1)
GROUP BY 
    ca.ca_city, 
    ca.ca_state
HAVING 
    COUNT(DISTINCT sales.c_customer_sk) > 0
ORDER BY 
    average_spent_per_customer DESC, 
    num_customers DESC;
