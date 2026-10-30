
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_credit_rating
    FROM 
        ranked_customers rc
    WHERE 
        rc.rnk <= 5
),
sales_summary AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid_inc_tax) AS total_revenue,
        AVG(cs.cs_net_paid) AS average_price
    FROM 
        catalog_sales cs
    LEFT JOIN 
        top_customers tc ON cs.cs_bill_customer_sk = tc.c_customer_sk
    WHERE 
        cs.cs_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        cs.cs_item_sk
),
return_summary AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned,
        SUM(cr.cr_return_amount) AS total_returned_value
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_order_number IN (
            SELECT 
                DISTINCT ws.ws_order_number 
            FROM 
                web_sales ws
            WHERE 
                ws.ws_ship_customer_sk IN (SELECT c_customer_sk FROM top_customers)
        )
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ss.total_quantity,
    ss.total_revenue,
    ss.average_price,
    COALESCE(rs.total_returned, 0) AS total_returned,
    COALESCE(rs.total_returned_value, 0) AS total_returned_value,
    CASE 
        WHEN ss.total_revenue > 10000 THEN 'High Revenue'
        WHEN ss.total_revenue >= 5000 AND ss.total_revenue <= 10000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    item i
LEFT JOIN 
    sales_summary ss ON i.i_item_sk = ss.cs_item_sk
LEFT JOIN 
    return_summary rs ON i.i_item_sk = rs.cr_item_sk
WHERE 
    (ss.total_quantity IS NOT NULL OR rs.total_returned > 0)
    AND (i.i_item_desc LIKE '%special%')
ORDER BY 
    revenue_category DESC, ss.total_revenue DESC NULLS LAST;
