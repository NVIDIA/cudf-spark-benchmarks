
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returns,
        AVG(cr_return_amt_inc_tax) AS avg_return_value,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
), 
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        cr.total_returns,
        cr.avg_return_value,
        cr.return_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY c.c_customer_id, cr.total_returns, cr.avg_return_value, cr.return_count
    ORDER BY total_sales DESC
    LIMIT 10
), 
SalesByWarehouse AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_revenue
    FROM warehouse w
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_id
)

SELECT 
    tc.c_customer_id,
    sbw.w_warehouse_id,
    sbw.total_orders,
    sbw.total_revenue,
    tc.total_sales,
    tc.total_returns,
    tc.avg_return_value,
    tc.return_count
FROM TopCustomers tc
JOIN SalesByWarehouse sbw ON tc.total_sales > 5000
ORDER BY sbw.total_revenue DESC, tc.total_sales DESC;
