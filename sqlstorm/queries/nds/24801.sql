
WITH RankedReturns AS (
    SELECT 
        cr.cr_item_sk, 
        cr.cr_order_number, 
        cr.cr_return_quantity, 
        cr.cr_return_amount, 
        cr.cr_refunded_customer_sk,
        ROW_NUMBER() OVER (PARTITION BY cr.cr_item_sk ORDER BY cr.cr_return_quantity DESC) AS rn
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_return_quantity IS NOT NULL 
        AND cr.cr_return_amount > 0 
        AND EXISTS (
            SELECT 1 
            FROM customer c 
            WHERE c.c_customer_sk = cr.cr_returning_customer_sk 
            AND c.c_birth_month = EXTRACT(MONTH FROM DATE '2002-10-01') 
            AND (c.c_preferred_cust_flag = 'Y' OR c.c_email_address IS NULL)
        )
),
ItemSales AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit 
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = EXTRACT(YEAR FROM DATE '2002-10-01') 
            AND d.d_moy BETWEEN 1 AND 6
        )
    GROUP BY 
        ws.ws_item_sk
),
ReturnStats AS (
    SELECT 
        rr.cr_item_sk,
        SUM(rr.cr_return_quantity) AS total_returns, 
        SUM(rr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT rr.cr_order_number) AS unique_orders
    FROM 
        RankedReturns rr
    WHERE 
        rr.rn <= 5
    GROUP BY 
        rr.cr_item_sk
)
SELECT 
    i.i_item_sk AS i_item_id, 
    COALESCE(st.total_sales, 0) AS total_sales,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN COALESCE(st.total_sales, 0) > 0 THEN ROUND(COALESCE(rs.total_return_amount, 0) / COALESCE(st.total_sales, 1) * 100, 2) 
        ELSE NULL 
    END AS return_percentage,
    CASE 
        WHEN rs.total_returns > 50 THEN 'High Return'
        WHEN rs.total_returns BETWEEN 20 AND 50 THEN 'Medium Return'
        ELSE 'Low Return'
    END AS return_category
FROM 
    item i
LEFT JOIN 
    ItemSales st ON i.i_item_sk = st.ws_item_sk
LEFT JOIN 
    ReturnStats rs ON i.i_item_sk = rs.cr_item_sk
WHERE 
    i.i_current_price IS NOT NULL 
    AND (i.i_item_desc LIKE '%Gadget%' OR i.i_item_desc LIKE '%Widget%')
ORDER BY 
    return_percentage DESC NULLS LAST, 
    i.i_item_id;
