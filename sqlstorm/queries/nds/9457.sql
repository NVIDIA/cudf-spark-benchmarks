
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_sales_price) AS total_sales, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk
),
BestSellingItems AS (
    SELECT 
        rs.ws_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        rs.total_quantity,
        rs.total_sales
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.rank <= 10
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesInsights AS (
    SELECT 
        c.c_first_name, 
        c.c_last_name, 
        bsi.i_item_desc, 
        bsi.i_brand, 
        bsi.i_category, 
        c.total_spent,
        bsi.total_sales
    FROM 
        BestSellingItems bsi
    JOIN 
        CustomerPurchases c ON c.total_spent > bsi.total_sales / 10
)
SELECT 
    s.c_first_name,
    s.c_last_name, 
    s.i_item_desc, 
    s.i_brand,
    s.i_category, 
    s.total_spent, 
    s.total_sales,
    (s.total_sales / NULLIF(s.total_spent, 0)) AS sales_to_spent_ratio
FROM 
    SalesInsights s
ORDER BY 
    sales_to_spent_ratio DESC
LIMIT 100;
