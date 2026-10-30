WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_ordered
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 2459580 AND 2459586 
    GROUP BY
        c.c_customer_id
), StoreSales AS (
    SELECT
        c.c_customer_id,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM
        customer c
    JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE
        ss.ss_sold_date_sk BETWEEN 2459580 AND 2459586 
    GROUP BY
        c.c_customer_id
), TotalSales AS (
    SELECT
        cs.c_customer_id,
        COALESCE(cs.total_web_sales, 0) AS web_sales,
        COALESCE(ss.total_store_sales, 0) AS store_sales,
        (COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0)) AS total_sales,
        cs.total_orders AS web_orders,
        ss.total_store_orders AS store_orders
    FROM
        CustomerSales cs
    FULL OUTER JOIN StoreSales ss ON cs.c_customer_id = ss.c_customer_id
)
SELECT
    t.c_customer_id,
    t.total_sales,
    t.web_sales,
    t.store_sales,
    CASE 
        WHEN t.total_sales > 5000 THEN 'High Value' 
        WHEN t.total_sales BETWEEN 1000 AND 5000 THEN 'Medium Value' 
        ELSE 'Low Value' 
    END AS customer_value_segment
FROM
    TotalSales t
ORDER BY
    total_sales DESC
LIMIT 100;