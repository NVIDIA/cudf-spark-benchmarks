
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        RANK() OVER (PARTITION BY sr_customer_sk ORDER BY sr_return_amt DESC) AS rnk
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
CustomerWarehouse AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        w.w_warehouse_name,
        COALESCE(NULLIF(ca.ca_state, ''), 'Unknown') AS ca_state
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        warehouse w ON w.w_warehouse_sk IN (
            SELECT 
                i.inv_warehouse_sk 
            FROM 
                inventory i 
            WHERE 
                i.inv_quantity_on_hand > 0
        )
)
SELECT 
    cw.c_first_name,
    cw.c_last_name,
    cw.ca_city,
    cw.ca_state,
    SUM(rr.sr_return_quantity) AS total_returned_quantity,
    SUM(rr.sr_return_amt) AS total_returned_amt,
    COUNT(rr.sr_customer_sk) AS count_of_returns,
    CASE 
        WHEN SUM(rr.sr_return_quantity) > 100 THEN 'High'
        WHEN SUM(rr.sr_return_quantity) BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low'
    END AS return_category
FROM 
    CustomerWarehouse cw
LEFT JOIN 
    RankedReturns rr ON cw.c_customer_sk = rr.sr_customer_sk AND rr.rnk = 1
GROUP BY 
    cw.c_first_name, cw.c_last_name, cw.ca_city, cw.ca_state
HAVING 
    SUM(rr.sr_return_quantity) IS NOT NULL 
    AND SUM(rr.sr_return_quantity) > 0
ORDER BY 
    return_category DESC, total_returned_amt DESC
LIMIT 100;
