
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS Sales_Rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_date >= '2023-01-01' 
        AND d_date <= '2023-12-31'
        LIMIT 1
    )
),
HighValueReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_amt_inc_tax) AS Total_Return_Amount,
        COUNT(sr_ticket_number) AS Return_Count
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_item_sk
    HAVING SUM(sr_return_amt_inc_tax) > 100 AND COUNT(sr_ticket_number) > 5
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cb.ca_country,
        RANK() OVER (PARTITION BY cb.ca_country ORDER BY cd.cd_purchase_estimate DESC) AS Country_Rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address cb ON c.c_current_addr_sk = cb.ca_address_sk
)
SELECT 
    R.ws_item_sk,
    COUNT(DISTINCT R.ws_order_number) AS Unique_Orders,
    AVG(R.ws_net_paid) AS Avg_Sale_Amount,
    COALESCE(H.Total_Return_Amount, 0) AS Total_Return_Amount,
    MAX(CD.cd_purchase_estimate) AS Max_Customer_Estimate,
    MAX(CD.cd_gender) AS Max_Gender,
    CASE 
        WHEN COUNT(DISTINCT R.ws_order_number) > 10 THEN 'High Order Volume'
        ELSE 'Low Order Volume'
    END AS Order_Volume_Status
FROM RankedSales R
LEFT JOIN HighValueReturns H ON R.ws_item_sk = H.sr_item_sk
JOIN CustomerDemographics CD ON R.ws_item_sk = CD.c_customer_sk
WHERE R.Sales_Rank <= 10
GROUP BY 
    R.ws_item_sk,
    H.Total_Return_Amount,
    CD.cd_purchase_estimate,
    CD.cd_gender
ORDER BY Avg_Sale_Amount DESC;
