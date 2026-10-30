
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) as sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450123 AND 2450130
    GROUP BY 
        ws_bill_customer_sk, ws_item_sk
),
TopSales AS (
    SELECT 
        r.ws_bill_customer_sk,
        r.ws_item_sk,
        r.total_sales,
        c.c_first_name,
        c.c_last_name
    FROM 
        RankedSales r
    JOIN 
        customer c ON r.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        r.sales_rank <= 10
)
SELECT 
    t.ws_bill_customer_sk,
    t.c_first_name,
    t.c_last_name,
    t.ws_item_sk,
    t.total_sales,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_item_sk = t.ws_item_sk) AS num_store_sales,
    (SELECT AVG(ss_ext_sales_price) FROM store_sales ss WHERE ss.ss_item_sk = t.ws_item_sk) AS avg_store_price,
    CASE 
        WHEN (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_item_sk = t.ws_item_sk) > 0 THEN 'Available in Store'
        ELSE 'Not Available in Store'
    END AS store_availability
FROM 
    TopSales t
ORDER BY 
    total_sales DESC;
