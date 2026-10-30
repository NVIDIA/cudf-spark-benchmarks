
WITH RankedSales AS (
    SELECT 
        ss_store_sk, 
        ss_sold_date_sk, 
        SUM(ss_quantity) AS total_quantity, 
        SUM(ss_net_paid) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk, 
        ss_sold_date_sk
),
CustomerReturns AS (
    SELECT 
        sr_store_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
),
CombinedData AS (
    SELECT 
        rs.ss_store_sk,
        rs.total_quantity,
        rs.total_net_paid,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        rs.sales_rank
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerReturns cr ON rs.ss_store_sk = cr.sr_store_sk
)

SELECT 
    s.s_store_name,
    ca.ca_state,
    ca.ca_country,
    cd.total_quantity,
    cd.total_net_paid,
    cd.total_returns,
    cd.total_return_amount,
    (cd.total_net_paid - cd.total_return_amount) AS net_revenue
FROM 
    CombinedData cd
JOIN 
    store s ON cd.ss_store_sk = s.s_store_sk
JOIN 
    customer_address ca ON s.s_store_sk = ca.ca_address_sk
WHERE 
    cd.sales_rank = 1
    AND cd.total_net_paid > 5000
ORDER BY 
    net_revenue DESC
LIMIT 10;
