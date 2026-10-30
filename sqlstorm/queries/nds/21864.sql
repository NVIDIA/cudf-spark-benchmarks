
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt) DESC) AS rank
    FROM 
        store_returns
    WHERE 
        sr_return_quantity IS NOT NULL
    GROUP BY 
        sr_item_sk
),
HighValueReturns AS (
    SELECT 
        r.sr_item_sk,
        r.total_returned,
        r.total_return_amount,
        i.i_item_desc,
        COALESCE(sm.sm_type, 'UNKNOWN') AS shipping_method,
        DENSE_RANK() OVER (ORDER BY r.total_return_amount DESC) AS value_rank
    FROM 
        RankedReturns r
    JOIN 
        item i ON r.sr_item_sk = i.i_item_sk
    LEFT JOIN 
        ship_mode sm ON r.sr_item_sk = sm.sm_ship_mode_sk
    WHERE 
        r.total_returned > 10
),
CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        SUM(hr.total_returned) AS customer_total_returns,
        SUM(hr.total_return_amount) AS customer_total_return_amount
    FROM 
        customer c
    JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    JOIN 
        HighValueReturns hr ON sr.sr_item_sk = hr.sr_item_sk
    WHERE 
        c.c_birth_year IS NOT NULL 
        AND c.c_birth_month IS NOT NULL
        AND (c.c_last_name NOT LIKE '%x%' OR c.c_last_name IS NULL)
    GROUP BY 
        c.c_customer_id
)
SELECT 
    c.c_customer_id,
    cr.customer_total_returns,
    cr.customer_total_return_amount,
    CASE 
        WHEN cr.customer_total_returns > 0 THEN 'ACTIVE'
        WHEN cr.customer_total_returns IS NULL THEN 'NO RETURNS'
        ELSE 'INACTIVE'
    END AS return_status,
    COUNT(DISTINCT hr.sr_item_sk) AS unique_returned_items
FROM 
    CustomerReturns cr
LEFT JOIN 
    HighValueReturns hr ON cr.customer_total_returns > hr.total_returned
JOIN 
    customer c ON cr.c_customer_id = c.c_customer_id
WHERE 
    (c.c_current_addr_sk IS NULL OR EXISTS (
        SELECT 1 
        FROM customer_address ca 
        WHERE ca.ca_address_sk = c.c_current_addr_sk 
          AND ca.ca_state = 'CA'
    ))
GROUP BY 
    c.c_customer_id, cr.customer_total_returns, cr.customer_total_return_amount
HAVING 
    SUM(cr.customer_total_return_amount) > (SELECT AVG(customer_total_return_amount) FROM CustomerReturns)
ORDER BY 
    RANDOM()  
LIMIT 100;
