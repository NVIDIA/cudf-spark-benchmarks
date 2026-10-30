
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
), 
SalesByReason AS (
    SELECT 
        r.r_reason_desc,
        SUM(ws.ws_ext_sales_price) AS total_sales_by_reason
    FROM 
        web_sales ws
    JOIN 
        web_returns wr ON ws.ws_item_sk = wr.wr_item_sk
    JOIN 
        reason r ON wr.wr_reason_sk = r.r_reason_sk
    GROUP BY 
        r.r_reason_desc
), 
TopCustomers AS (
    SELECT 
        cs.c_customer_id, 
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    tc.c_customer_id, 
    tc.total_sales, 
    sr.total_sales_by_reason,
    tc.sales_rank
FROM 
    TopCustomers tc
LEFT JOIN 
    SalesByReason sr ON sr.total_sales_by_reason IS NOT NULL
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.sales_rank;
