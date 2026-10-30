
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_item_sk
),
HighProfitItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales.total_profit,
        sales.total_orders
    FROM 
        item
    JOIN 
        SalesData sales ON item.i_item_sk = sales.ws_item_sk
    WHERE 
        sales.profit_rank <= 10
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COALESCE(NULLIF(cd_credit_rating, 'bad'), 'unknown') AS sanitized_credit_rating,
        COUNT(c.c_customer_sk) AS num_customers
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status, cd_credit_rating
)
SELECT 
    HPI.i_item_desc,
    HPI.total_profit,
    HPI.total_orders,
    CD.cd_gender,
    CD.sanitized_credit_rating,
    CD.num_customers
FROM 
    HighProfitItems HPI
FULL OUTER JOIN 
    CustomerDemographics CD ON HPI.total_orders > 5 AND CD.num_customers > 0
ORDER BY 
    HPI.total_profit DESC, CD.cd_gender;
