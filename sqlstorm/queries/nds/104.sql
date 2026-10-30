
WITH CustomerReturnSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(sr_return_quantity), 0) AS total_return_quantity,
        COALESCE(SUM(sr_return_amt), 0) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM
        customer AS c
    LEFT JOIN
        store_returns AS sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics AS cd
    JOIN customer AS c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
RefundedCustomers AS (
    SELECT 
        DISTINCT sr.sr_customer_sk
    FROM 
        store_returns AS sr
    WHERE 
        sr.sr_return_amt > 0
),
WebSaleSummary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS web_order_count,
        SUM(ws_net_paid_inc_ship) AS total_web_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cs.total_return_quantity,
    cs.total_return_amount,
    cd.customer_count,
    COALESCE(ws.web_order_count, 0) AS web_order_count,
    COALESCE(ws.total_web_sales, 0) AS total_web_sales
FROM 
    CustomerReturnSummary AS cs
LEFT JOIN 
    CustomerDemographics AS cd ON cs.c_customer_sk = cd.cd_demo_sk
LEFT JOIN 
    WebSaleSummary AS ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    (cs.total_return_quantity > 0 OR cs.total_return_amount > 0)
AND 
    (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
ORDER BY 
    total_return_amount DESC
LIMIT 100;
