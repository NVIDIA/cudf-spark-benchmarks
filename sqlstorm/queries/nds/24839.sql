
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
HighlyProfitableCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_net_profit,
        cs.order_count,
        (SELECT AVG(total_net_profit) 
         FROM CustomerSales 
         WHERE order_count > 5) AS avg_high_volume_profit
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_net_profit > (SELECT MAX(total_net_profit) FROM CustomerSales) * 0.75
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender, 
        cd.cd_marital_status, 
        COUNT(DISTINCT c.c_customer_id) AS demographic_count
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    hpc.c_customer_id,
    hpc.total_net_profit,
    hpc.order_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.demographic_count
FROM 
    HighlyProfitableCustomers hpc
JOIN 
    CustomerDemographics cd ON hpc.c_customer_id IN (SELECT c.c_customer_id FROM customer c WHERE c.c_current_cdemo_sk IN (SELECT cd.cd_demo_sk FROM customer_demographics cd WHERE cd.cd_marital_status = 'M'))
WHERE 
    cd.demographic_count > (SELECT AVG(demographic_count) FROM CustomerDemographics)
UNION ALL
SELECT 
    NULL AS c_customer_id,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS order_count,
    NULL AS cd_gender,
    NULL AS cd_marital_status,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_demographic_count
FROM 
    store_sales ss
WHERE 
    ss.ss_sales_price IS NOT NULL OR ss.ss_net_profit IS NULL
GROUP BY 
    ss.ss_sold_date_sk
ORDER BY 
    total_net_profit DESC NULLS LAST;
