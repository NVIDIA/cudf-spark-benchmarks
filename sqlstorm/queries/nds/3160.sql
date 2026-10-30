
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM 
        web_sales
    WHERE 
        ws_quantity > 0
),
TotalSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales_amount
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        count(DISTINCT ws_order_number) AS total_orders
    FROM 
        customer
    JOIN 
        web_sales ON c_customer_sk = ws_bill_customer_sk
    GROUP BY 
        c_customer_sk, c_first_name, c_last_name
    HAVING 
        COUNT(DISTINCT ws_order_number) > 1
),
ItemDetail AS (
    SELECT 
        i_item_sk,
        i_product_name,
        i_current_price,
        i_item_id
    FROM 
        item
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    id.i_product_name,
    ts.total_quantity_sold,
    ts.total_sales_amount,
    COALESCE(rs.ws_sales_price, 0) AS highest_web_sale_price
FROM 
    CustomerInfo ci
JOIN 
    TotalSales ts ON ci.c_customer_sk = ts.ws_item_sk
JOIN 
    ItemDetail id ON ts.ws_item_sk = id.i_item_sk
LEFT JOIN 
    RankedSales rs ON ts.ws_item_sk = rs.ws_item_sk AND rs.price_rank = 1
WHERE 
    ts.total_quantity_sold > 100
    AND id.i_current_price IS NOT NULL 
    AND id.i_item_id LIKE 'A%'
ORDER BY 
    ts.total_sales_amount DESC
LIMIT 50;
