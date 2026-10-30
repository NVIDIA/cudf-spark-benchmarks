
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_sales_price, 
        ws_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_quantity DESC) AS quantity_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL 
        AND ws_quantity > 0
), HighValueSales AS (
    SELECT 
        item.i_item_id,
        RS.ws_sales_price,
        RS.ws_quantity,
        (RS.ws_sales_price * RS.ws_quantity) AS total_value
    FROM 
        RankedSales RS
    JOIN 
        item ON RS.ws_item_sk = item.i_item_sk
    WHERE 
        RS.price_rank = 1 
        AND RS.quantity_rank = 1
), CustomerData AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        hd.hd_buy_potential
), FinalOutput AS (
    SELECT 
        CV.c_customer_id,
        CV.order_count,
        COUNT(DISTINCT HVS.i_item_id) AS high_value_item_count,
        SUM(HVS.total_value) AS total_high_value
    FROM 
        CustomerData CV
    LEFT JOIN 
        HighValueSales HVS ON CV.c_customer_id = HVS.i_item_id
    GROUP BY 
        CV.c_customer_id, 
        CV.order_count
)
SELECT 
    FO.c_customer_id,
    FO.order_count,
    COALESCE(FO.high_value_item_count, 0) AS high_value_item_count,
    FO.total_high_value,
    CASE 
        WHEN FO.total_high_value > 1000 THEN 'Gold'
        WHEN FO.total_high_value BETWEEN 500 AND 1000 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_tier
FROM 
    FinalOutput FO
WHERE 
    FO.order_count > 0
ORDER BY 
    FO.total_high_value DESC
LIMIT 10;
