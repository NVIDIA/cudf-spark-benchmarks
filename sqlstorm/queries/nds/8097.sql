
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price * ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
PopularItems AS (
    SELECT 
        i_item_id,
        i_product_name,
        rs.total_sales
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.sales_rank <= 10
),
CustomerPurchaseStats AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
),
HighSpenders AS (
    SELECT 
        c.c_customer_id,
        cps.total_orders,
        cps.total_spent
    FROM 
        CustomerPurchaseStats cps
    JOIN 
        customer c ON cps.c_customer_id = c.c_customer_id
    WHERE 
        cps.total_spent > (SELECT AVG(total_spent) FROM CustomerPurchaseStats)
)
SELECT 
    pi.i_product_name,
    pi.total_sales,
    hs.total_orders,
    hs.total_spent
FROM 
    PopularItems pi
JOIN 
    HighSpenders hs ON hs.total_orders > 5
ORDER BY 
    pi.total_sales DESC;
