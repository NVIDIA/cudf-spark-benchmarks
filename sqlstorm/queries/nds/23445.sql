
WITH ranked_sales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_net_paid,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS rank_sales,
        CASE 
            WHEN ws_net_paid > (SELECT AVG(ws_net_paid) FROM web_sales) THEN 'Above Average' 
            ELSE 'Below Average' 
        END AS sales_category
    FROM 
        web_sales
),
customer_info AS (
    SELECT 
        c_customer_sk,
        c_first_name || ' ' || c_last_name AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
return_details AS (
    SELECT 
        wr_item_sk, 
        wr_order_number,
        SUM(wr_return_quantity) AS total_returned,
        COUNT(DISTINCT wr_returning_customer_sk) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk, 
        wr_order_number
),
final_analysis AS (
    SELECT 
        cs.ws_item_sk, 
        cs.ws_order_number,
        cs.ws_net_paid,
        COALESCE(rs.total_returned, 0) AS total_returned,
        COALESCE(rs.return_count, 0) AS return_count,
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        CASE
            WHEN rs.total_returned > 0 THEN 'Returned'
            WHEN cs.ws_net_paid = 0 THEN 'Freebie'
            ELSE 'Sold'
        END AS sale_status
    FROM 
        ranked_sales cs
    JOIN 
        customer_info ci ON cs.ws_order_number = ci.c_customer_sk
    LEFT JOIN 
        return_details rs ON cs.ws_item_sk = rs.wr_item_sk AND cs.ws_order_number = rs.wr_order_number
    WHERE 
        (ci.cd_purchase_estimate > 5000 AND ci.cd_gender = 'F') OR 
        (ci.cd_purchase_estimate < 200 AND ci.cd_marital_status IS NULL)
)
SELECT 
    fa.ws_item_sk, 
    fa.ws_order_number,
    fa.ws_net_paid,
    fa.total_returned,
    fa.return_count,
    fa.full_name,
    fa.cd_gender,
    fa.cd_marital_status,
    fa.cd_purchase_estimate,
    fa.sale_status
FROM 
    final_analysis fa
WHERE 
    fa.total_returned > (
        SELECT AVG(total_returned) FROM return_details
    )
ORDER BY 
    fa.ws_net_paid DESC, 
    fa.total_returned ASC;

