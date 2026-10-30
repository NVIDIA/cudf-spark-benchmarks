
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_qty,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
DailySales AS (
    SELECT 
        ws_bill_customer_sk,
        d.d_date,
        SUM(ws_net_profit) AS total_sales_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws_bill_customer_sk, d.d_date
),
RankedSales AS (
    SELECT 
        ds.ws_bill_customer_sk,
        ds.d_date,
        ds.total_sales_profit,
        ds.total_orders,
        ROW_NUMBER() OVER (PARTITION BY ds.ws_bill_customer_sk ORDER BY ds.total_sales_profit DESC) AS sales_rank
    FROM 
        DailySales ds
)
SELECT 
    ca.ca_address_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cr.total_returned_qty, 0) AS total_returned_qty,
    COALESCE(cr.total_returned_amt, 0) AS total_returned_amt,
    rs.total_sales_profit,
    rs.total_orders
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
LEFT JOIN 
    RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk AND rs.sales_rank = 1
WHERE 
    ca.ca_state = 'CA'
    AND (cr.total_returned_qty > 0 OR rs.total_sales_profit IS NOT NULL)
ORDER BY 
    total_returned_qty DESC, 
    total_sales_profit DESC;
