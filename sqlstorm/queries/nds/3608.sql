WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank_sales
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        ws.ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        COALESCE(AVG(cd.cd_dep_count), 0) AS avg_dep_count
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
StoreStatistics AS (
    SELECT 
        s.s_store_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM 
        store s
    LEFT JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    GROUP BY 
        s.s_store_sk
),
ReturnInsights AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_quantity) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
),
CombinedInsights AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(sd.total_quantity_sold, 0) AS quantity_sold,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(cs.avg_dep_count, 0) AS average_dependencies,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_return_amount, 0) AS total_return_amount
    FROM 
        customer c
    LEFT JOIN 
        SalesData sd ON c.c_customer_sk = sd.ws_item_sk
    LEFT JOIN 
        CustomerDemographics cs ON c.c_current_cdemo_sk = cs.cd_demo_sk
    LEFT JOIN 
        ReturnInsights r ON c.c_customer_sk = r.sr_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales > 10000 THEN 'High Value'
        WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    CombinedInsights
WHERE 
    quantity_sold > 0
ORDER BY 
    quantity_sold DESC, total_sales DESC;