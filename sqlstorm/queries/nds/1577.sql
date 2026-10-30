
WITH SalesSummary AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS average_sales_price
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_name
),
CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesWithReturns AS (
    SELECT 
        ss.w_warehouse_name,
        ss.total_quantity_sold,
        ss.total_sales,
        ss.total_orders,
        ss.average_sales_price,
        COALESCE(cr.total_returns, 0) AS total_returns,
        cr.total_returned_amount
    FROM 
        SalesSummary ss
    LEFT JOIN 
        CustomerReturns cr ON cr.c_customer_id IS NOT NULL
)
SELECT 
    s.w_warehouse_name,
    s.total_quantity_sold,
    s.total_sales,
    s.total_orders,
    s.average_sales_price,
    s.total_returns,
    s.total_returned_amount,
    (s.total_sales - s.total_returned_amount) AS net_sales,
    CASE 
        WHEN s.total_orders = 0 THEN 0 
        ELSE (s.total_sales / s.total_orders) 
    END AS average_order_value,
    RANK() OVER (ORDER BY (s.total_sales - s.total_returned_amount) DESC) AS sales_rank
FROM 
    SalesWithReturns s
WHERE 
    s.total_sales > 1000
ORDER BY 
    sales_rank
LIMIT 10;
