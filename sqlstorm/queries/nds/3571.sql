
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS rank
    FROM web_sales
),
HighValueItems AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid) AS total_net_paid
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY ws_item_sk
    HAVING SUM(ws_net_paid) > 1000
),
TopCustomers AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_paid) AS total_spent
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
    HAVING SUM(ws_net_paid) > 500
),
ItemDetails AS (
    SELECT 
        i_item_sk,
        i_item_id,
        i_product_name,
        i_current_price,
        COALESCE(p.p_promo_name, 'None') AS promo_name
    FROM item i
    LEFT JOIN promotion p ON i.i_item_sk = p.p_item_sk AND p.p_start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
)
SELECT 
    cu.c_customer_id,
    cu.c_first_name,
    cu.c_last_name,
    it.i_product_name,
    SUM(rs.ws_net_paid) AS total_spent,
    AVG(rs.ws_sales_price) AS avg_sales_price,
    SUBSTRING(it.i_product_name FROM 1 FOR 50) AS product_name_short,
    ROW_NUMBER() OVER (PARTITION BY cu.c_customer_id ORDER BY SUM(rs.ws_net_paid) DESC) AS customer_rank
FROM 
    TopCustomers tc
JOIN 
    web_sales ws ON tc.ws_bill_customer_sk = ws.ws_bill_customer_sk
JOIN 
    ItemDetails it ON ws.ws_item_sk = it.i_item_sk
JOIN 
    customer cu ON tc.ws_bill_customer_sk = cu.c_customer_sk
JOIN 
    RankedSales rs ON ws.ws_item_sk = rs.ws_item_sk
WHERE 
    ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
    AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    AND it.i_current_price IS NOT NULL
GROUP BY 
    cu.c_customer_id, cu.c_first_name, cu.c_last_name, it.i_product_name
ORDER BY 
    total_spent DESC
LIMIT 100;
