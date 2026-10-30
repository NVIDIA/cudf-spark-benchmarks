WITH CustomerReturnStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returned,
        COUNT(DISTINCT sr_ticket_number) AS unique_returns,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(SUM(sr_return_quantity), 0) DESC) AS return_rank
    FROM 
        customer c 
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
PromotionalSales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws 
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        p.p_start_date_sk < (SELECT d_date_sk FROM date_dim WHERE d_date = cast('2002-10-01' as date)) 
        AND p.p_end_date_sk > (SELECT d_date_sk FROM date_dim WHERE d_date = cast('2002-10-01' as date))
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_returned,
    cs.unique_returns,
    COALESCE(ps.total_sales, 0) AS total_sales
FROM 
    CustomerReturnStats cs
LEFT JOIN 
    PromotionalSales ps ON cs.c_customer_sk = ps.ws_bill_customer_sk
WHERE 
    cs.return_rank <= 10
ORDER BY 
    cs.total_returned DESC, 
    total_sales DESC;