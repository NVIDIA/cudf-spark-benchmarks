
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TopItems AS (
    SELECT 
        r.ws_item_sk,
        SUM(r.ws_quantity) AS total_quantity,
        SUM(r.ws_sales_price * r.ws_quantity) AS total_sales
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 10
    GROUP BY 
        r.ws_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        d.d_month_seq
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ti.total_quantity,
    ti.total_sales
FROM 
    TopItems ti
JOIN 
    CustomerInfo ci ON ti.ws_item_sk = ws_item_sk
ORDER BY 
    ti.total_sales DESC
LIMIT 100;
