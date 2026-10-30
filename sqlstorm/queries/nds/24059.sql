
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_item_sk, 
        ws.ws_order_number
),
ReturnData AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(DISTINCT wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_quantity
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd 
    WHERE 
        cd.cd_purchase_estimate > (
            SELECT AVG(cd2.cd_purchase_estimate) 
            FROM customer_demographics cd2
        )
)
SELECT 
    sd.ws_item_sk,
    COALESCE(rd.total_returns, 0) AS total_returns,
    sd.total_quantity,
    sd.total_net_paid,
    COALESCE(rd.total_return_amt, 0) AS total_return_amt,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    sd.max_sales_price,
    sd.min_sales_price,
    sd.avg_sales_price,
    CASE 
        WHEN sd.total_net_paid > 10000 THEN 'High Value Customer'
        WHEN sd.total_net_paid <= 10000 AND sd.total_net_paid > 5000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value,
    ROW_NUMBER() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_quantity DESC) AS rank_within_item
FROM 
    SalesData sd
LEFT JOIN 
    ReturnData rd ON sd.ws_item_sk = rd.wr_item_sk
JOIN 
    CustomerDemographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_first_name IS NOT NULL LIMIT 1)
WHERE 
    sd.total_quantity > (SELECT AVG(sd2.total_quantity) FROM SalesData sd2)
ORDER BY 
    customer_value DESC,
    sd.total_net_paid DESC
LIMIT 100;
