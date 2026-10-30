
WITH SalesData AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS SalesRank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 20.00
),
TopSellingItems AS (
    SELECT
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS TotalQuantity,
        SUM(sd.ws_net_profit) AS TotalProfit
    FROM SalesData sd
    WHERE sd.SalesRank <= 5
    GROUP BY sd.ws_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        COUNT(DISTINCT ws.ws_order_number) AS TotalOrders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    ci.TotalQuantity,
    ci.TotalProfit,
    CASE 
        WHEN ci.TotalProfit > 1000 THEN 'High'
        WHEN ci.TotalProfit BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low' 
    END AS ProfitCategory
FROM TopSellingItems ci
JOIN CustomerData cd ON ci.ws_item_sk = cd.c_customer_sk
WHERE cd.TotalOrders > 0
ORDER BY ci.TotalProfit DESC
LIMIT 10;
