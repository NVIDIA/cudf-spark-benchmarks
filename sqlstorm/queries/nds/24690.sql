
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rnk
    FROM 
        web_sales
    WHERE 
        ws_net_profit IS NOT NULL
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_net_profit,
        COALESCE(AVG(cs_ext_sales_price), 0) AS avg_catalog_price
    FROM 
        RankedSales rs
    LEFT JOIN 
        catalog_sales cs ON rs.ws_item_sk = cs.cs_item_sk
    WHERE 
        rs.rnk <= 5
    GROUP BY 
        rs.ws_item_sk, rs.ws_order_number, rs.ws_net_profit
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_dep_count, 0) AS dependent_count,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    ts.ws_item_sk,
    ts.ws_order_number,
    ts.ws_net_profit,
    ts.avg_catalog_price,
    CASE 
        WHEN ts.ws_net_profit > ts.avg_catalog_price THEN 'Profitable' 
        ELSE 'Not Profitable' 
    END AS profitability_status,
    CASE 
        WHEN cd.dependent_count IS NULL OR cd.dependent_count = 0 THEN 'No Dependents'
        WHEN cd.dependent_count >= 5 THEN 'Large Family'
        ELSE 'Moderate Family'
    END AS family_status
FROM 
    TopSales ts
JOIN 
    CustomerDetails cd ON cd.c_customer_sk = ts.ws_order_number 
WHERE 
    cd.c_first_name IS NOT NULL
AND 
    cd.c_last_name IS NOT NULL
ORDER BY 
    ts.ws_net_profit DESC, cd.c_last_name, cd.c_first_name
LIMIT 100;
