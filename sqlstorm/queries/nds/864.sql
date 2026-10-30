
WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt) AS total_return_amount,
        SUM(wr_return_tax) AS total_return_tax,
        COUNT(*) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
SalesData AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_net_paid) AS total_sales_amount,
        COUNT(*) AS sales_count
    FROM 
        web_sales
    GROUP BY 
        ws_ship_customer_sk
),
CustomerPerformance AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SD.total_sales_quantity, 0) AS total_sales_quantity,
        COALESCE(SD.total_sales_amount, 0) AS total_sales_amount,
        COALESCE(R.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(R.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN COALESCE(SD.total_sales_quantity, 0) = 0 THEN 0
            ELSE COALESCE(R.total_returned_quantity, 0) * 100.0 / COALESCE(SD.total_sales_quantity, 0)
        END AS return_rate_percentage
    FROM 
        customer c
    LEFT JOIN 
        SalesData SD ON c.c_customer_sk = SD.ws_ship_customer_sk
    LEFT JOIN 
        CustomerReturns R ON c.c_customer_sk = R.wr_returning_customer_sk
),
RankedPerformance AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        total_sales_quantity,
        total_sales_amount,
        total_returned_quantity,
        total_return_amount,
        return_rate_percentage,
        RANK() OVER (ORDER BY return_rate_percentage DESC) AS rank
    FROM 
        CustomerPerformance
)
SELECT 
    c_customer_sk AS customer_sk,
    c_first_name,
    c_last_name,
    total_sales_quantity,
    total_sales_amount,
    total_returned_quantity,
    total_return_amount,
    return_rate_percentage,
    rank
FROM 
    RankedPerformance
WHERE 
    return_rate_percentage > 0
ORDER BY 
    return_rate_percentage DESC
LIMIT 10;
