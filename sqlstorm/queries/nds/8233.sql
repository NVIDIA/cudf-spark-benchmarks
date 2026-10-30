
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopSellingItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        RankedSales.total_quantity,
        RankedSales.total_sales_price
    FROM 
        RankedSales
    JOIN 
        item ON RankedSales.ws_item_sk = item.i_item_sk
    WHERE 
        RankedSales.sales_rank = 1
),
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(ws.ws_sales_price) > 1000
)
SELECT 
    TSI.i_item_id,
    TSI.i_item_desc,
    TSI.total_quantity,
    TSI.total_sales_price,
    CS.c_customer_id,
    CS.total_spent
FROM 
    TopSellingItems TSI
JOIN 
    CustomerSales CS ON TSI.total_quantity > 50
ORDER BY 
    TSI.total_sales_price DESC, CS.total_spent DESC
LIMIT 10;
