
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        MAX(d.d_date) AS last_purchase_date
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesOverview AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        cs.last_purchase_date,
        CASE 
            WHEN cs.total_sales IS NULL THEN 'No Sales'
            WHEN cs.total_sales < 100 THEN 'Low Value Customer'
            WHEN cs.total_sales BETWEEN 100 AND 500 THEN 'Medium Value Customer'
            ELSE 'High Value Customer'
        END AS customer_value
    FROM 
        CustomerSales cs
)
SELECT 
    svo.c_first_name,
    svo.c_last_name,
    svo.total_sales,
    svo.order_count,
    svo.last_purchase_date,
    svo.customer_value,
    COALESCE(NULLIF(sb.best_item, ''), 'No Purchases') AS best_item
FROM 
    SalesOverview svo
LEFT JOIN (
    SELECT 
        ws.ws_bill_customer_sk,
        i.i_item_desc AS best_item,
        RANK() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY SUM(ws.ws_quantity) DESC) AS item_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        ws.ws_bill_customer_sk, i.i_item_desc
) sb ON svo.c_customer_sk = sb.ws_bill_customer_sk AND sb.item_rank = 1
ORDER BY 
    svo.total_sales DESC;
