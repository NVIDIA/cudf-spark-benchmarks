
WITH TopCustomers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
    HAVING 
        SUM(ws.ws_net_paid_inc_tax) > 1000
), RecentReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS returns_count,
        SUM(sr_return_amt_inc_tax) AS total_returned
    FROM 
        store_returns 
    GROUP BY 
        sr_customer_sk
), CustomerDetails AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.cd_gender,
        COALESCE(rr.returns_count, 0) AS returns_count,
        COALESCE(rr.total_returned, 0) AS total_returned,
        ROW_NUMBER() OVER (PARTITION BY tc.cd_gender ORDER BY tc.total_spent DESC) AS rank
    FROM 
        TopCustomers tc
    LEFT JOIN 
        RecentReturns rr ON tc.c_customer_sk = rr.sr_customer_sk
)

SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.returns_count,
    cd.total_returned,
    CASE 
        WHEN cd.rank <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS customer_category
FROM 
    CustomerDetails cd
WHERE 
    cd.returns_count > 0
    AND cd.cd_gender = 'F'
ORDER BY 
    cd.total_returned DESC
LIMIT 10;
