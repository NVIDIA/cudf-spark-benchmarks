
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopSales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        COALESCE(s.total_quantity, 0) AS total_sales_quantity,
        COALESCE(s.total_net_paid, 0.00) AS total_sales_value
    FROM 
        item
    LEFT JOIN 
        SalesCTE s ON item.i_item_sk = s.ws_item_sk
    WHERE 
        s.rank <= 5 OR s.rank IS NULL
)

SELECT 
    a.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    AVG(COALESCE(ts.total_sales_value, 0)) AS avg_sales_value,
    STRING_AGG(DISTINCT ts.i_product_name, ', ') AS top_products
FROM 
    customer c
JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN 
    TopSales ts ON c.c_customer_sk = ts.total_sales_quantity
WHERE 
    a.ca_state = 'CA' 
    AND c.c_preferred_cust_flag = 'Y'
GROUP BY 
    a.ca_city
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY 
    avg_sales_value DESC
LIMIT 10;
