WITH  CustomerLifetimeValue AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(SUM(ws.ws_net_profit), 0) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
), RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        clv.total_sales,
        clv.total_orders,
        RANK() OVER (ORDER BY clv.total_sales DESC) AS customer_rank
    FROM 
        CustomerLifetimeValue clv
    JOIN 
        customer c ON clv.c_customer_sk = c.c_customer_sk
    WHERE 
        clv.total_sales > (SELECT AVG(total_sales) FROM CustomerLifetimeValue)
)
SELECT 
    r.c_customer_id,
    r.total_sales,
    r.total_orders,
    RANK() OVER (ORDER BY r.total_orders DESC) AS order_rank,
    CASE 
        WHEN r.total_sales > 1000 THEN 'High Value'
        WHEN r.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    RankedCustomers r
WHERE 
    r.customer_rank <= 10
ORDER BY 
    r.total_sales DESC;