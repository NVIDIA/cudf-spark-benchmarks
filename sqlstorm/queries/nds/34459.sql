
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_order_number
), 
ItemDetails AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_desc, 
        i.i_brand, 
        i.i_category, 
        d.d_year, 
        d.d_month_seq
    FROM 
        item i 
    JOIN 
        date_dim d ON d.d_date_sk = (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
), 
CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_paid) AS total_net_paid, 
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    id.i_item_desc,
    id.i_brand,
    id.i_category,
    COALESCE(cs.total_net_paid, 0) AS total_net_paid,
    COALESCE(cs.order_count, 0) AS order_count,
    s.total_quantity,
    s.total_sales
FROM 
    ItemDetails id
LEFT JOIN 
    SalesCTE s ON id.i_item_sk = s.ws_item_sk AND s.sales_rank = 1
LEFT JOIN 
    CustomerSales cs ON cs.total_net_paid > 0
WHERE 
    id.d_year = 2023
    AND id.i_item_desc LIKE '%Gadget%'
    AND (s.total_sales IS NOT NULL OR cs.order_count > 0)
ORDER BY 
    total_sales DESC
LIMIT 10;
