
WITH SalesSummary AS (
    SELECT
        d.d_year AS Sales_Year,
        SUM(ws.ws_net_profit) AS Total_Profit,
        COUNT(DISTINCT ws.ws_order_number) AS Total_Orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS Unique_Customers
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY
        d.d_year
),
CustomerDemographics AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS Customer_Count
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY
        cd.cd_gender, cd.cd_marital_status
),
PromotionImpact AS (
    SELECT
        p.p_promo_name AS promo_name,
        SUM(ws.ws_net_profit) AS Profit_With_Promo
    FROM
        web_sales ws
    JOIN
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY
        p.p_promo_name
)
SELECT
    ss.Sales_Year,
    ss.Total_Profit,
    ss.Total_Orders,
    ss.Unique_Customers,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.Customer_Count,
    pi.promo_name,
    pi.Profit_With_Promo
FROM
    SalesSummary ss
JOIN
    CustomerDemographics cd ON cd.Customer_Count > 0
JOIN
    PromotionImpact pi ON ss.Total_Profit > 10000
ORDER BY
    ss.Sales_Year DESC, pi.Profit_With_Promo DESC;
