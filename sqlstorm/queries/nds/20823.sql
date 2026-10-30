
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        sr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
CustomerIncome AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band,
        COALESCE(cd.cd_marital_status, 'N') AS marital_status,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns
    FROM 
        customer c
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    WHERE 
        sr.sr_ticket_number IS NOT NULL
    GROUP BY 
        c.c_customer_sk,
        hd.hd_income_band_sk,
        cd.cd_marital_status
),
TopReturns AS (
    SELECT 
        cr.c_customer_sk,
        SUM(cr.total_returns) AS return_count,
        RANK() OVER (ORDER BY SUM(cr.total_returns) DESC) AS return_rank
    FROM 
        CustomerIncome cr
    GROUP BY 
        cr.c_customer_sk
    HAVING 
        SUM(cr.total_returns) BETWEEN 1 AND 10
),
SalesData AS (
    SELECT 
        ss.ss_customer_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_sales_price) AS average_sales_price,
        COUNT(DISTINCT ss.ss_ticket_number) AS sale_count,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_paid
    FROM 
        store_sales ss
    LEFT JOIN 
        CustomerIncome ci ON ss.ss_customer_sk = ci.c_customer_sk
    GROUP BY 
        ss.ss_customer_sk
),
FinalResults AS (
    SELECT 
        ci.c_customer_sk,
        ci.marital_status,
        s.total_net_profit,
        s.sale_count,
        t.return_rank,
        s.total_paid
    FROM 
        CustomerIncome ci
    LEFT JOIN 
        SalesData s ON ci.c_customer_sk = s.ss_customer_sk
    LEFT JOIN 
        TopReturns t ON ci.c_customer_sk = t.c_customer_sk
)
SELECT 
    f.c_customer_sk,
    f.marital_status,
    COALESCE(f.total_net_profit, 0) AS net_profit,
    COALESCE(f.sale_count, 0) AS sales_count,
    COALESCE(f.return_rank, 999) AS return_rank,
    CASE 
        WHEN f.total_paid > 1000 THEN 'High Value'
        WHEN f.total_paid BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value
FROM 
    FinalResults f
ORDER BY 
    f.marital_status ASC, net_profit DESC;
