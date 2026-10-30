
WITH CustomerReturnStats AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned_amount,
        AVG(sr.sr_return_quantity) AS avg_returned_quantity
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
), 
HighValueReturns AS (
    SELECT 
        cr.c_customer_id,
        cr.total_returns,
        cr.total_returned_amount,
        cr.avg_returned_quantity,
        kd.bin_width
    FROM 
        CustomerReturnStats cr
    JOIN 
        (SELECT 
            ib_income_band_sk,
            (ib_upper_bound - ib_lower_bound) AS bin_width
         FROM 
            income_band 
         WHERE 
            ib_upper_bound > 10000) kd ON cr.total_returned_amount > kd.bin_width
), 
TopCustomerReturns AS (
    SELECT 
        cr.c_customer_id AS customer_id,
        cr.total_returns,
        cr.total_returned_amount,
        cr.avg_returned_quantity,
        ROW_NUMBER() OVER (ORDER BY cr.total_returned_amount DESC) AS rn
    FROM 
        HighValueReturns cr
)
SELECT 
    t.customer_id,
    t.total_returns,
    t.total_returned_amount,
    t.avg_returned_quantity,
    CONCAT('Customer ', CAST(t.customer_id AS STRING), ' has a total return amount of $', CAST(ROUND(t.total_returned_amount, 2) AS STRING)) AS return_summary
FROM 
    TopCustomerReturns t
WHERE 
    t.rn <= 10
ORDER BY 
    t.total_returned_amount DESC;
