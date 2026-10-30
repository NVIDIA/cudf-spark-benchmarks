
WITH RankedSales AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk, ws_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        cd.cd_gender,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
TopItems AS (
    SELECT 
        ri.ws_item_sk,
        ri.total_quantity,
        ri.total_sales,
        ci.ca_city,
        ci.cd_gender,
        ci.hd_income_band_sk,
        ci.hd_buy_potential
    FROM 
        RankedSales ri
    JOIN 
        CustomerInfo ci ON ri.ws_item_sk = ci.c_customer_sk
    WHERE 
        ri.sales_rank <= 5
)
SELECT 
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_sales,
    ti.ca_city,
    ti.cd_gender,
    CASE 
        WHEN ti.hd_income_band_sk IS NULL THEN 'Unknown'
        WHEN ti.hd_income_band_sk BETWEEN 1 AND 3 THEN 'Low Income'
        WHEN ti.hd_income_band_sk BETWEEN 4 AND 6 THEN 'Middle Income'
        ELSE 'High Income' 
    END AS income_bracket,
    COUNT(*) OVER (PARTITION BY ti.ca_city, ti.cd_gender) AS city_gender_count
FROM 
    TopItems ti
WHERE 
    ti.hd_buy_potential IS NOT NULL
ORDER BY 
    ti.total_sales DESC;
