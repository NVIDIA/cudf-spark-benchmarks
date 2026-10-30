
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopItems AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_sales,
        i.i_item_desc,
        i.i_current_price,
        ROW_NUMBER() OVER (ORDER BY r.total_sales DESC) AS item_rank
    FROM 
        RankedSales r
    INNER JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.rank = 1
)
SELECT 
    ti.item_rank,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    ti.total_sales / NULLIF(ti.total_quantity, 0) AS avg_sales_price,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM 
    TopItems ti
JOIN 
    customer c ON ti.ws_item_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ca.ca_country = 'USA'
ORDER BY 
    ti.total_sales DESC
LIMIT 100;
