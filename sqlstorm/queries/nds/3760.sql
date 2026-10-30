WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rank
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
RecentReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim) 
    GROUP BY 
        sr_customer_sk
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_purchase_estimate,
        rr.return_count,
        rr.total_return_amt
    FROM 
        RankedCustomers rc
        LEFT JOIN RecentReturns rr ON rc.c_customer_sk = rr.sr_customer_sk
    WHERE 
        rc.rank <= 10
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 90 FROM date_dim) 
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    tc.c_customer_sk,
    CONCAT(tc.c_first_name, ' ', tc.c_last_name) AS full_name,
    tc.cd_gender,
    tc.cd_marital_status,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_profit, 0) AS total_profit,
    COALESCE(tc.return_count, 0) AS return_count,
    COALESCE(tc.total_return_amt, 0) AS total_return_amt,
    CASE 
        WHEN tc.return_count > 5 THEN 'High Return Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    TopCustomers tc
    LEFT JOIN SalesSummary ss ON tc.c_customer_sk = ss.ws_bill_customer_sk
ORDER BY 
    total_sales DESC, 
    tc.return_count DESC;