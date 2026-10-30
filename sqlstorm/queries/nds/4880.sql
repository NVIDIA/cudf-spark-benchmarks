WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_rec_start_date <= cast('2002-10-01' as date) AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > cast('2002-10-01' as date))
    GROUP BY 
        ws.ws_item_sk
),
TopSellingItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_paid
    FROM 
        SalesData sd
    WHERE 
        sd.sales_rank <= 10
),
CustomerReturns AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_quantity) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_value, 0) AS total_return_value,
    ti.total_quantity,
    ti.total_net_paid,
    (CASE 
        WHEN COALESCE(cr.total_return_value, 0) > 0 THEN 'High Return' 
        ELSE 'Low Return' 
     END) AS return_category
FROM 
    customer c
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
LEFT JOIN 
    TopSellingItems ti ON c.c_customer_sk = ti.ws_item_sk
WHERE 
    c.c_current_addr_sk IS NOT NULL
ORDER BY 
    ti.total_net_paid DESC NULLS LAST;