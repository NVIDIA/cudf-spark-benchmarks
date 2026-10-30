
WITH AddressCounts AS (
    SELECT 
        ca_city, 
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        MAX(ca_street_name) AS longest_street_name
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
CustomerDemoGender AS (
    SELECT 
        cd_gender, 
        COUNT(c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
PromotionDetails AS (
    SELECT 
        p.p_promo_name,
        SUM(p.p_cost) AS total_cost
    FROM 
        promotion p
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        p.p_promo_name
),
SalesInfo AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
),
FinalReport AS (
    SELECT 
        ac.ca_city AS city,
        ac.unique_addresses,
        ac.longest_street_name,
        cdg.cd_gender,
        cdg.customer_count,
        pd.p_promo_name,
        pd.total_cost,
        si.total_sales,
        si.total_profit
    FROM 
        AddressCounts ac
    CROSS JOIN 
        CustomerDemoGender cdg
    JOIN 
        PromotionDetails pd ON pd.total_cost > 0
    JOIN 
        SalesInfo si ON si.total_sales > 1000
)
SELECT * 
FROM FinalReport
ORDER BY 
    city, cd_gender, total_sales DESC;
