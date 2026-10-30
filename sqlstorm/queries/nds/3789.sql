WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rnk
    FROM 
        web_sales
),
AggregateSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales,
        COUNT(rs.ws_quantity) AS number_of_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.rnk = 1
    GROUP BY 
        rs.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr_refunded_customer_sk,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(wr_returning_customer_sk) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_refunded_customer_sk
),
TopCustomers AS (
    SELECT 
        cr.wr_refunded_customer_sk,
        RANK() OVER (ORDER BY cr.total_return_amt DESC) AS customer_rank
    FROM 
        CustomerReturns cr
    WHERE 
        cr.total_return_amt > 0
),
FinalReport AS (
    SELECT 
        a.ws_item_sk,
        a.total_sales,
        coalesce(c.total_return_amt, 0) AS total_return_amt,
        coalesce(c.return_count, 0) AS return_count,
        t.customer_rank
    FROM 
        AggregateSales a
    LEFT JOIN 
        CustomerReturns c ON c.wr_refunded_customer_sk = a.ws_item_sk 
    LEFT JOIN 
        TopCustomers t ON t.wr_refunded_customer_sk = c.wr_refunded_customer_sk
)
SELECT 
    fr.ws_item_sk,
    fr.total_sales,
    fr.total_return_amt,
    fr.return_count,
    CASE 
        WHEN fr.customer_rank IS NOT NULL THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    FinalReport fr
WHERE 
    fr.total_sales > 1000
ORDER BY 
    fr.total_sales DESC;