WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
WarehouseSales AS (
    SELECT 
        ws_warehouse_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451545 AND 2451886 
    GROUP BY ws_warehouse_sk
),
RankedReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(cr.return_count, 0) AS return_count,
        RANK() OVER (ORDER BY COALESCE(cr.total_return_amount, 0) DESC) AS return_rank
    FROM customer c
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
),
AggregatedWarehouseSales AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        ws.total_sales,
        ws.total_orders,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_sk ORDER BY ws.total_sales DESC) AS sales_rank
    FROM warehouse w
    LEFT JOIN WarehouseSales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
)
SELECT 
    r.c_first_name,
    r.c_last_name,
    r.total_return_amount,
    r.return_count,
    w.w_warehouse_name,
    w.total_sales,
    w.total_orders,
    CASE 
        WHEN r.return_count > 0 THEN 'Active Customer'
        ELSE 'New Customer'
    END AS customer_status,
    CASE 
        WHEN w.total_sales > 1000 THEN 'High Sales'
        WHEN w.total_sales BETWEEN 500 AND 1000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM RankedReturns r
JOIN AggregatedWarehouseSales w ON r.c_customer_sk = w.w_warehouse_sk 
WHERE r.return_rank <= 10 AND w.sales_rank <= 5
ORDER BY r.total_return_amount DESC, w.total_sales DESC;