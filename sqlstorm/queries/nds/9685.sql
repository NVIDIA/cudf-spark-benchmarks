
WITH Sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        AVG(ws_net_paid) AS average_sales,
        COUNT(ws_order_number) AS number_of_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        ws_item_sk
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(cd_purchase_estimate) AS total_estimated_purchases
    FROM 
        customer_demographics 
    JOIN customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status
),
TopItems AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity,
        s.total_sales,
        s.average_sales,
        DENSE_RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank 
    FROM 
        Sales s 
    WHERE 
        s.total_sales > 1000
),
FinalReport AS (
    SELECT 
        ti.ws_item_sk,
        ti.total_quantity,
        ti.total_sales,
        ti.average_sales,
        d.cd_gender,
        d.cd_marital_status,
        d.customer_count,
        d.total_estimated_purchases
    FROM 
        TopItems ti
    LEFT JOIN 
        Demographics d 
    ON ti.ws_item_sk = d.cd_demo_sk
    WHERE 
        ti.sales_rank <= 10
)
SELECT 
    fr.ws_item_sk,
    fr.total_quantity,
    fr.total_sales,
    fr.average_sales,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.customer_count,
    fr.total_estimated_purchases
FROM 
    FinalReport fr
ORDER BY 
    fr.total_sales DESC;
