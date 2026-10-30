
WITH TopCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 30 
        AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY 
        total_net_profit DESC
    LIMIT 10
), CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
), SalesStats AS (
    SELECT
        cs.cs_order_number,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(cs.cs_item_sk) AS number_of_items
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sold_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        cs.cs_order_number
), AverageSales AS (
    SELECT 
        AVG(total_profit) AS avg_sales_profit,
        AVG(number_of_items) AS avg_items_per_order
    FROM 
        SalesStats
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    cd.hd_buy_potential,
    COALESCE(
        CASE 
            WHEN tc.total_net_profit > aps.avg_sales_profit THEN 'Above Average' 
            ELSE 'Below Average' 
        END, 
        'Not Available'
    ) AS performance
FROM 
    TopCustomers tc
LEFT JOIN 
    CustomerDemographics cd ON tc.c_customer_sk = cd.cd_demo_sk
LEFT JOIN 
    AverageSales aps ON TRUE
ORDER BY 
    tc.total_net_profit DESC;
