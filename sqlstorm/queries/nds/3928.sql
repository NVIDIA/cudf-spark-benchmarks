
WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt) AS total_returned_amt,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
HighReturnCustomers AS (
    SELECT 
        cr.wr_returning_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (ORDER BY cr.total_returned_quantity DESC) AS rank_qty,
        RANK() OVER (ORDER BY cr.total_returned_amt DESC) AS rank_amt
    FROM 
        CustomerReturns cr
    JOIN 
        customer c ON c.c_customer_sk = cr.wr_returning_customer_sk
    JOIN 
        customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE 
        cr.total_returned_quantity > 10 AND 
        cr.total_returned_amt > 100
)
SELECT 
    hrc.wr_returning_customer_sk,
    CONCAT(hrc.c_first_name, ' ', hrc.c_last_name) AS customer_name,
    hrc.cd_gender,
    hrc.cd_marital_status,
    hrc.cd_purchase_estimate,
    CASE 
        WHEN hrc.rank_qty < 11 THEN 'Top 10 by Quantity'
        WHEN hrc.rank_amt < 11 THEN 'Top 10 by Amount'
        ELSE 'Not in Top 10'
    END AS return_rank_category
FROM 
    HighReturnCustomers hrc
WHERE 
    hrc.rank_qty < 11 OR hrc.rank_amt < 11
ORDER BY 
    hrc.rank_qty, hrc.rank_amt;
