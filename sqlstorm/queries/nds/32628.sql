
WITH  sales_data AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_ext_sales_price) AS total_sales 
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk

    UNION ALL
    
    SELECT 
        cs_sold_date_sk, 
        cs_item_sk, 
        SUM(cs_quantity) AS total_quantity, 
        SUM(cs_ext_sales_price) AS total_sales 
    FROM 
        catalog_sales 
    WHERE 
        cs_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cs_sold_date_sk, cs_item_sk
),

customer_return_data AS (
    SELECT 
        cr_returning_customer_sk, 
        SUM(cr_return_quantity) AS total_returned_quantity, 
        SUM(cr_return_amount) AS total_returned_amount
    FROM 
        catalog_returns 
    GROUP BY 
        cr_returning_customer_sk
),

total_sales AS (
    SELECT 
        s.ws_item_sk, 
        COALESCE(sd.total_quantity, 0) AS web_sales_quantity,
        COALESCE(sd.total_sales, 0) AS web_sales_amount, 
        COALESCE(rd.total_returned_quantity, 0) AS total_returned_quantity, 
        COALESCE(rd.total_returned_amount, 0) AS total_returned_amount
    FROM 
        (SELECT DISTINCT ws_item_sk FROM web_sales) s
    LEFT JOIN sales_data sd ON s.ws_item_sk = sd.ws_item_sk 
    LEFT JOIN customer_return_data rd ON rd.cr_returning_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_customer_id = 'CUST007')
)

SELECT 
    ts.ws_item_sk, 
    ts.web_sales_quantity, 
    ts.web_sales_amount, 
    ts.total_returned_quantity, 
    ts.total_returned_amount,
    (ts.web_sales_amount - ts.total_returned_amount) AS net_revenue 
FROM 
    total_sales ts
WHERE 
    (ts.web_sales_quantity > 1000 OR ts.total_returned_quantity < 50)
ORDER BY 
    net_revenue DESC
LIMIT 10;
