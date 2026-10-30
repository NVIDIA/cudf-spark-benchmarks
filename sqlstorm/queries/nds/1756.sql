
WITH CustomerStats AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_purchase_estimate
    FROM CustomerStats cs
    WHERE cs.rnk <= 5
),
WebSalesInfo AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN TopCustomers tc ON ws.ws_bill_customer_sk = tc.c_customer_sk
    GROUP BY ws.ws_item_sk
),
StoreSalesInfo AS (
    SELECT
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS ticket_count
    FROM store_sales ss
    JOIN TopCustomers tc ON ss.ss_customer_sk = tc.c_customer_sk
    GROUP BY ss.ss_item_sk
),
SalesComparison AS (
    SELECT
        w.ws_item_sk,
        w.total_quantity AS web_quantity,
        w.total_sales AS web_sales,
        COALESCE(s.total_quantity, 0) AS store_quantity,
        COALESCE(s.total_sales, 0) AS store_sales,
        (w.total_sales - COALESCE(s.total_sales, 0)) AS sales_difference
    FROM WebSalesInfo w
    LEFT JOIN StoreSalesInfo s ON w.ws_item_sk = s.ss_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    AVG(CASE WHEN sc.web_quantity > 0 THEN sc.web_sales / sc.web_quantity ELSE NULL END) AS avg_web_sales_per_item,
    AVG(CASE WHEN sc.store_quantity > 0 THEN sc.store_sales / sc.store_quantity ELSE NULL END) AS avg_store_sales_per_item,
    COUNT(sc.sales_difference) AS num_items_with_sales_diff,
    SUM(sc.sales_difference) AS total_sales_difference
FROM SalesComparison sc
JOIN item i ON sc.ws_item_sk = i.i_item_sk
GROUP BY i.i_item_id, i.i_item_desc
HAVING SUM(CASE WHEN sc.sales_difference > 0 THEN 1 ELSE 0 END) > 10
ORDER BY total_sales_difference DESC
LIMIT 10;
