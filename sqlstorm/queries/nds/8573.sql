
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year >= 1980 
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_net_profit,
        cs.order_count,
        ROW_NUMBER() OVER (ORDER BY cs.total_net_profit DESC) AS rank
    FROM 
        CustomerSales cs
),
SelectedIncomeBands AS (
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        income_band ib
    WHERE 
        ib.ib_upper_bound > 50000
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ci.total_net_profit
    FROM 
        customer_demographics cd
    JOIN 
        CustomerSales ci ON cd.cd_demo_sk IN (
            SELECT 
                c.c_current_cdemo_sk 
            FROM 
                customer c 
            WHERE 
                c.c_customer_id IN (SELECT c_customer_id FROM TopCustomers WHERE rank <= 10)
        )
),
FinalReport AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(cd.total_net_profit) AS avg_net_profit,
        COUNT(cd.cd_demo_sk) AS customer_count
    FROM 
        CustomerDemographics cd
    WHERE 
        cd.total_net_profit IS NOT NULL
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    fr.cd_gender,
    fr.cd_marital_status,
    fr.avg_net_profit,
    fr.customer_count,
    ib.ib_income_band_sk
FROM 
    FinalReport fr
JOIN 
    SelectedIncomeBands ib ON fr.avg_net_profit BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
ORDER BY 
    fr.avg_net_profit DESC;
