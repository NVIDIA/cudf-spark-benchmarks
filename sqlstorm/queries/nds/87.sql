
WITH TotalSales AS (
    SELECT 
        ws_item_sk, 
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_revenue
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status, cd_education_status
),
HighValuedItems AS (
    SELECT 
        i_item_sk, 
        i_item_desc, 
        i_current_price,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS item_rank
    FROM 
        web_sales 
    JOIN 
        item ON ws_item_sk = i_item_sk
    GROUP BY 
        i_item_sk, i_item_desc, i_current_price
    HAVING 
        SUM(ws_net_paid_inc_tax) > 1000
)
SELECT 
    i.i_item_desc, 
    i.i_current_price, 
    ts.total_orders, 
    ts.total_quantity, 
    ts.total_revenue, 
    cd.cd_marital_status,
    cd.cd_gender,
    cd.customer_count
FROM 
    HighValuedItems i
JOIN 
    TotalSales ts ON i.i_item_sk = ts.ws_item_sk
LEFT JOIN 
    CustomerDemographics cd ON cd.customer_count > 0
WHERE 
    i.item_rank <= 10
ORDER BY 
    ts.total_revenue DESC
