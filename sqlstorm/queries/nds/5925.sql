
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        r.ws_item_sk, 
        r.total_quantity, 
        r.total_sales,
        i.i_item_desc,
        ROW_NUMBER() OVER (ORDER BY r.total_sales DESC) AS rank
    FROM 
        RankedSales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.sales_rank = 1
)
SELECT 
    ti.rank,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales
FROM 
    TopItems ti
WHERE 
    ti.rank <= 10
ORDER BY 
    ti.total_sales DESC;
