
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        COALESCE(SUM(CASE WHEN sr_return_quantity IS NOT NULL THEN sr_return_quantity ELSE 0 END), 0) AS total_return_quantity,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, full_name
),
ItemPopularity AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COUNT(cs.cs_order_number) AS order_count,
        AVG(cs.cs_sales_price) AS avg_sales_price
    FROM 
        item i
    LEFT JOIN 
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
),
TopItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        order_count,
        avg_sales_price,
        ROW_NUMBER() OVER (ORDER BY order_count DESC) AS rnk
    FROM 
        ItemPopularity i
)
SELECT 
    cr.full_name,
    ti.i_item_id,
    ti.order_count,
    cr.total_return_quantity,
    cr.total_return_amt,
    CASE 
        WHEN cr.total_return_quantity > 0 THEN 'High Return Customer'
        ELSE 'Regular Customer' 
    END AS customer_category
FROM 
    CustomerReturns cr
INNER JOIN 
    TopItems ti ON cr.total_returns > 0 AND ti.rnk <= 5
WHERE 
    cr.total_returns > (SELECT AVG(total_returns) FROM CustomerReturns)
ORDER BY 
    cr.total_return_amt DESC;
