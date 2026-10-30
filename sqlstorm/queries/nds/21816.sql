
WITH  CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) as total_returns,
        COUNT(DISTINCT sr_ticket_number) as return_count
    FROM 
        store_returns 
    WHERE 
        sr_returned_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr_customer_sk
    HAVING 
        SUM(sr_return_quantity) > 0
), CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_buy_potential, 'UNKNOWN') AS buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
), ReturnAnalysis AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        r.total_returns,
        r.return_count,
        CASE 
            WHEN r.total_returns IS NULL THEN 'No Returns'
            WHEN r.return_count < 5 THEN 'Occasional Returner'
            ELSE 'Frequent Returner'
        END AS return_category
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        CustomerReturns r ON cd.c_customer_sk = r.sr_customer_sk
)
SELECT 
    ra.c_customer_sk,
    ra.c_first_name,
    ra.c_last_name,
    ra.cd_gender,
    ra.cd_marital_status,
    ra.cd_purchase_estimate,
    ra.total_returns,
    ra.return_count,
    ra.return_category,
    SUM(ws.ws_net_paid) AS total_net_paid,
    DENSE_RANK() OVER (PARTITION BY ra.return_category ORDER BY SUM(ws.ws_net_paid) DESC) AS rank_within_category
FROM 
    ReturnAnalysis ra
LEFT JOIN 
    web_sales ws ON ra.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
GROUP BY 
    ra.c_customer_sk, ra.c_first_name, ra.c_last_name, ra.cd_gender, ra.cd_marital_status, ra.cd_purchase_estimate, ra.total_returns, ra.return_count, ra.return_category
HAVING 
    SUM(ws.ws_net_paid) IS NOT NULL AND SUM(ws.ws_net_paid) > 0
ORDER BY 
    ra.return_category, total_net_paid DESC;
