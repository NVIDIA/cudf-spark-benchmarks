
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_paid > 0
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(SUM(CASE WHEN rs.rn = 1 THEN rs.ws_net_paid ELSE 0 END), 0) AS latest_sales,
        COALESCE(SUM(CASE WHEN rs.rn = 2 THEN rs.ws_net_paid ELSE 0 END), 0) AS second_latest_sales
    FROM 
        item i
    LEFT JOIN 
        RankedSales rs ON i.i_item_sk = rs.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc, i.i_current_price
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(CASE WHEN id.latest_sales > 500 THEN id.latest_sales ELSE 0 END), 0) AS high_value_sales
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN 
        ItemDetails id ON c.c_customer_sk = id.i_item_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
ShippingModes AS (
    SELECT 
        sm.sm_ship_mode_sk,
        sm.sm_type,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_ship_cost) AS total_ship_cost
    FROM 
        ship_mode sm
    LEFT JOIN 
        web_sales ws ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_sk, sm.sm_type
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(cd.high_value_sales) AS total_high_value_sales,
    sm.sm_type AS shipping_type,
    MAX(sm.order_count) AS max_orders,
    COALESCE(SUM(cd.high_value_sales), 0) AS total_high_value_sales_with_shipping
FROM 
    CustomerDemographics cd
FULL OUTER JOIN 
    ShippingModes sm ON cd.cd_gender = 'M' AND sm.total_ship_cost > 100
GROUP BY 
    cd.cd_gender, cd.cd_marital_status, sm.sm_type
HAVING 
    (SUM(cd.high_value_sales) > 1000 OR (MAX(sm.order_count) >= 50))
ORDER BY 
    total_high_value_sales DESC, max_orders DESC NULLS LAST;
