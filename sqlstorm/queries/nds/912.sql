
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, sr_item_sk, sr_customer_sk
),
TopReturns AS (
    SELECT 
        rr.sr_item_sk,
        rr.total_returned_quantity,
        rr.total_returned_amt,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY rr.sr_item_sk ORDER BY rr.total_returned_amt DESC) AS customer_rank
    FROM 
        RankedReturns rr
    JOIN 
        customer c ON rr.sr_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        rr.return_rank = 1
),
SalesData AS (
    SELECT 
        w.ws_item_sk,
        SUM(w.ws_quantity) AS total_sold_quantity,
        SUM(w.ws_ext_sales_price) AS total_sold_amt
    FROM 
        web_sales w
    GROUP BY 
        w.ws_item_sk
),
Comparison AS (
    SELECT 
        tr.sr_item_sk,
        tr.total_returned_quantity,
        tr.total_returned_amt,
        sd.total_sold_quantity,
        sd.total_sold_amt,
        (tr.total_returned_amt / NULLIF(sd.total_sold_amt, 0)) AS return_to_sales_ratio
    FROM 
        TopReturns tr
    JOIN 
        SalesData sd ON tr.sr_item_sk = sd.ws_item_sk
)
SELECT 
    c.sr_item_sk,
    c.total_returned_quantity,
    c.total_returned_amt,
    c.total_sold_quantity,
    c.total_sold_amt,
    c.return_to_sales_ratio,
    CASE 
        WHEN c.return_to_sales_ratio > 0.5 THEN 'High Return'
        WHEN c.return_to_sales_ratio <= 0.5 AND c.return_to_sales_ratio > 0 THEN 'Moderate Return'
        ELSE 'No Returns'
    END AS return_category
FROM 
    Comparison c
WHERE 
    c.total_sold_quantity > 100
ORDER BY 
    c.return_to_sales_ratio DESC
LIMIT 20;
