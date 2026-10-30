WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sales_price DESC) AS rank_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_date = cast('2002-10-01' as date)
        )
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        COUNT(*) AS return_count
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk = (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_date = cast('2002-10-01' as date)
        )
    GROUP BY 
        wr_returning_customer_sk
),
SalesWithReturns AS (
    SELECT 
        r.ws_bill_customer_sk,
        r.ws_item_sk,
        r.ws_quantity,
        r.ws_sales_price,
        COALESCE(t.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(t.return_count, 0) AS return_count
    FROM 
        RankedSales r
    LEFT JOIN 
        CustomerReturns t 
    ON 
        r.ws_bill_customer_sk = t.wr_returning_customer_sk
    WHERE 
        r.rank_sales <= 5
)
SELECT 
    ca.ca_address_id,
    SUM(ws_ext_sales_price) AS total_sales,
    AVG(ws_ext_discount_amt) AS average_discount,
    MAX(ws_net_profit) AS max_profit,
    MIN(ws_net_paid) AS min_paid,
    CASE 
        WHEN COUNT(DISTINCT r.ws_item_sk) > 0 THEN 'Returns Made'
        ELSE 'No Returns'
    END AS return_status
FROM 
    SalesWithReturns r
JOIN 
    customer c ON r.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON r.ws_item_sk = ws.ws_item_sk AND r.ws_bill_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ws.ws_sold_date_sk = (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_date = cast('2002-10-01' as date)
    )
GROUP BY 
    ca.ca_address_id
HAVING 
    MAX(ws_net_paid) > (
        SELECT AVG(ws_net_paid) 
        FROM web_sales 
        WHERE ws_sold_date_sk = (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_date = cast('2002-10-01' as date)
        )
    )
ORDER BY 
    total_sales DESC
LIMIT 10;