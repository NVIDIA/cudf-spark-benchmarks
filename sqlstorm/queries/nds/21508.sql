
WITH RankedSales AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_net_paid_inc_tax) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY ss_customer_sk ORDER BY SUM(ss_net_paid_inc_tax) DESC) AS rank_within_customer,
        RANK() OVER (ORDER BY SUM(ss_net_paid_inc_tax) DESC) AS overall_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        ss_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE((SELECT COUNT(*) FROM customer_demographics WHERE cd_demo_sk = c.c_current_cdemo_sk), 0) AS demo_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL
),
ReturnDetails AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_returned
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
FinalReport AS (
    SELECT 
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(rs.total_spent, 0) AS total_spent,
        COALESCE(rd.return_count, 0) AS return_count,
        COALESCE(rd.total_returned, 0) AS total_returned,
        CASE 
            WHEN COALESCE(rs.rank_within_customer, 0) = 1 THEN 'Top Spender'
            WHEN COALESCE(rs.rank_within_customer, 0) <= 3 THEN 'High Spender'
            ELSE 'Regular Spender'
        END AS spending_category
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        RankedSales rs ON cd.c_customer_sk = rs.ss_customer_sk
    LEFT JOIN 
        ReturnDetails rd ON cd.c_customer_sk = rd.sr_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN return_count > 0 THEN 'Returned'
        ELSE 'No Returns'
    END AS return_status,
    CASE 
        WHEN total_spent IS NULL OR total_spent = 0 THEN 'Inactive'
        ELSE 'Active'
    END AS activity_status
FROM 
    FinalReport
WHERE 
    cd_gender IS NOT NULL 
ORDER BY 
    total_spent DESC, 
    return_count ASC NULLS LAST;
