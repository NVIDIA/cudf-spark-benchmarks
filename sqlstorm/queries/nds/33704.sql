
WITH  SalesRank AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2452159 AND 2452195
    GROUP BY ws_bill_customer_sk
), CTE_Customer AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band_sk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), MaxReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS return_count
    FROM store_returns
    GROUP BY sr_customer_sk
    HAVING COUNT(*) > 5
), CustomerWithReturns AS (
    SELECT 
        cu.*,
        COALESCE(mr.return_count, 0) AS return_count
    FROM CTE_Customer cu
    LEFT JOIN MaxReturns mr ON cu.c_customer_sk = mr.sr_customer_sk
)
SELECT 
    cwr.c_customer_sk,
    cwr.c_first_name,
    cwr.c_last_name,
    cwr.ca_city,
    cwr.ca_state,
    CASE 
        WHEN cwr.return_count > 0 THEN 'High Return Customer' 
        ELSE 'Regular Customer' 
    END AS customer_type,
    sr.total_profit,
    CASE 
        WHEN sr.rank <= 10 THEN 'Top Performer' 
        WHEN sr.rank <= 50 THEN 'Average Performer' 
        ELSE 'Low Performer' 
    END AS performance_category
FROM CustomerWithReturns cwr
LEFT JOIN SalesRank sr ON cwr.c_customer_sk = sr.ws_bill_customer_sk
WHERE cwr.income_band_sk IS NOT NULL
ORDER BY performance_category, total_profit DESC;
