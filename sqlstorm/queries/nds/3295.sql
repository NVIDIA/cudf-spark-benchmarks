WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
ReturnInfo AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS total_returned,
        COUNT(sr.sr_ticket_number) AS total_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
),
NetSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales - COALESCE(ri.total_returned, 0) AS net_sales,
        cs.total_orders
    FROM 
        CustomerSales cs
    LEFT JOIN 
        ReturnInfo ri ON cs.c_customer_sk = ri.sr_customer_sk
)

SELECT 
    ns.c_customer_sk,
    ns.total_orders,
    ns.net_sales,
    cs.c_first_name,
    cs.c_last_name,
    COALESCE(ri.total_returns, 0) AS total_returns
FROM 
    NetSales ns
JOIN 
    CustomerSales cs ON ns.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    ReturnInfo ri ON ns.c_customer_sk = ri.sr_customer_sk
WHERE 
    ns.net_sales > 1000
    AND cs.sales_rank <= 10
ORDER BY 
    ns.net_sales DESC;