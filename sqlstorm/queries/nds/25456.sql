
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
CustomerStatistics AS (
    SELECT
        rc.c_customer_sk,
        rc.c_first_name || ' ' || rc.c_last_name AS full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        COALESCE(return_count, 0) AS return_count,
        COALESCE(total_return_amt, 0.00) AS total_return_amt,
        CASE 
            WHEN COALESCE(return_count, 0) > 10 THEN 'High Return Customer'
            WHEN COALESCE(return_count, 0) BETWEEN 5 AND 10 THEN 'Medium Return Customer'
            ELSE 'Low Return Customer'
        END AS customer_return_category
    FROM 
        RankedCustomers rc
),
AggregatedStats AS (
    SELECT
        cd.cd_gender,
        COUNT(*) AS customer_count,
        AVG(return_count) AS avg_return_count,
        SUM(total_return_amt) AS total_return_amount
    FROM 
        CustomerStatistics cd
    GROUP BY 
        cd.cd_gender
)
SELECT
    ag.cd_gender,
    ag.customer_count,
    ag.avg_return_count,
    ag.total_return_amount,
    RANK() OVER (ORDER BY ag.total_return_amount DESC) AS revenue_rank
FROM 
    AggregatedStats ag
ORDER BY 
    ag.total_return_amount DESC;
