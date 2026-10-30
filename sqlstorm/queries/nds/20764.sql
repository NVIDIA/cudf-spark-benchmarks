
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS Rank,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS DenseRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (
            SELECT MAX(d.d_date_sk) 
            FROM date_dim d 
            WHERE d.d_year = 2023 AND d.d_month_seq < 6
        ) AND (
            SELECT MIN(d.d_date_sk) 
            FROM date_dim d 
            WHERE d.d_year = 2023 AND d.d_month_seq > 6
        )
),
CustomerReturns AS (
    SELECT 
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_customer_sk,
        COALESCE(c.c_first_name, 'Unknown') AS customer_first_name,
        COALESCE(c.c_last_name, 'Unknown') AS customer_last_name
    FROM 
        store_returns sr
    LEFT JOIN 
        customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE 
        sr.sr_returned_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),
TotalReturns AS (
    SELECT 
        cr.return_item,
        SUM(cr.sr_return_quantity) AS total_returned_items,
        SUM(cr.sr_return_amt) AS total_returned_amount,
        COUNT(DISTINCT cr.customer_return_id) AS unique_customers_returned
    FROM (
        SELECT 
            sr.sr_item_sk AS return_item,
            sr.sr_return_quantity,
            sr.sr_return_amt,
            ROW_NUMBER() OVER (PARTITION BY sr.sr_customer_sk ORDER BY sr.sr_returned_date_sk DESC) AS customer_return_id
        FROM 
            store_returns sr
    ) cr
    GROUP BY cr.return_item
)
SELECT 
    r.ws_item_sk,
    r.Rank,
    COALESCE(t.total_returned_items, 0) AS total_returned_items,
    COALESCE(t.total_returned_amount, 0.00) AS total_returned_amount,
    COUNT(DISTINCT c.customer_first_name) FILTER (WHERE c.customer_first_name IS NOT NULL) AS returning_customers_count,
    SUM(CASE WHEN t.unique_customers_returned > 5 THEN 1 ELSE 0 END) AS frequent_returners
FROM 
    RankedSales r
LEFT JOIN 
    TotalReturns t ON r.ws_item_sk = t.return_item
LEFT JOIN 
    CustomerReturns c ON c.sr_return_amt > 50.00
WHERE 
    r.Rank <= 5 OR (r.DenseRank BETWEEN 1 AND 5 AND r.ws_sales_price IS NOT NULL)
GROUP BY 
    r.ws_item_sk, r.Rank, t.total_returned_items, t.total_returned_amount
ORDER BY 
    r.ws_item_sk, r.Rank;
