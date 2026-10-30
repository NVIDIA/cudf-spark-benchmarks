
WITH customer_return_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(sr_return_amt) DESC) AS return_rank
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_returns AS (
    SELECT 
        cr.c_customer_sk,
        cr.c_first_name,
        cr.c_last_name,
        cr.total_returns,
        cr.total_return_amount
    FROM 
        customer_return_stats cr
    WHERE 
        cr.return_rank <= 10
),
items_returned AS (
    SELECT 
        sr.sr_item_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS return_value
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        ir.return_count,
        ir.return_value,
        COALESCE(ir.return_count, 0) AS absolute_return_count,
        COALESCE(ir.return_value, 0) AS absolute_return_value
    FROM 
        item i
    LEFT JOIN 
        items_returned ir ON i.i_item_sk = ir.sr_item_sk
)
SELECT 
    tr.c_first_name,
    tr.c_last_name,
    id.i_item_desc,
    id.i_current_price,
    id.absolute_return_count,
    id.absolute_return_value
FROM 
    top_returns tr
JOIN 
    web_sales ws ON tr.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item_details id ON ws.ws_item_sk = id.i_item_sk
WHERE 
    id.absolute_return_count > 0 OR id.absolute_return_value > 100
ORDER BY 
    tr.total_return_amount DESC, 
    id.absolute_return_value DESC;
