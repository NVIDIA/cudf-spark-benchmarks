WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) as rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
SalesSummary AS (
    SELECT 
        rs.ws_order_number,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales,
        AVG(rs.ws_sales_price) AS avg_sales_price
    FROM
        RankedSales rs
    WHERE 
        rs.rank <= 5
    GROUP BY 
        rs.ws_order_number
),
CustomerReturns AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
        COUNT(sr.sr_ticket_number) AS return_count
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
)

SELECT 
    c.c_customer_id,
    cs.total_sales,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    CASE 
        WHEN cs.total_sales - COALESCE(cr.total_return_amt, 0) > 0 THEN 'Profit'
        ELSE 'Loss'
    END AS profit_status
FROM 
    customer c
LEFT JOIN 
    SalesSummary cs ON c.c_customer_sk = cs.ws_order_number
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
WHERE 
    c.c_first_name LIKE '%John%'
    AND (c.c_birth_year BETWEEN 1980 AND 1990 OR c.c_birth_country IS NULL)
ORDER BY 
    profit_status DESC,
    cs.total_sales DESC
LIMIT 10;