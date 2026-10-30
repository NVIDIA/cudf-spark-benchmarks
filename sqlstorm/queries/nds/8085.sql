
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price * ws_quantity) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        i.i_category,
        rs.total_quantity,
        rs.total_sales
    FROM RankedSales rs
    JOIN item i ON rs.ws_item_sk = i.i_item_sk
    WHERE rs.sales_rank = 1 
),
CustomerStats AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        AVG(ws.ws_ext_sales_price) AS avg_order_value
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    ts.ws_item_sk,
    ts.i_item_desc,
    ts.i_current_price,
    ts.i_brand,
    ts.i_category,
    cs.order_count,
    cs.total_spent,
    cs.avg_order_value
FROM TopItems ts
JOIN CustomerStats cs ON cs.order_count > 10
ORDER BY cs.total_spent DESC
LIMIT 50;
