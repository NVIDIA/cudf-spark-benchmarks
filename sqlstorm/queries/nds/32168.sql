
WITH  CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT wr_order_number) AS total_returns,
        ROW_NUMBER() OVER (PARTITION BY wr_returning_customer_sk ORDER BY SUM(wr_return_amt_inc_tax) DESC) AS rn
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(cr.total_returns, 0) AS total_returns
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk AND cr.rn = 1
    WHERE 
        cd.cd_purchase_estimate > 5000
        AND cd.cd_credit_rating IN ('Excellent', 'Good')
        AND COALESCE(cr.total_return_amount, 0) < 1000
),
HighValueItems AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        item i 
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_product_name
    HAVING 
        SUM(ws.ws_ext_sales_price) > 10000
)
SELECT 
    hvc.c_customer_id,
    hvc.ca_city,
    hvc.ca_state,
    hvi.i_product_name,
    hvi.total_sales,
    hvc.total_return_amount,
    hvc.total_returns
FROM 
    HighValueCustomers hvc
JOIN 
    HighValueItems hvi ON hvc.cd_purchase_estimate > 5000
ORDER BY 
    hvc.total_return_amount DESC,
    hvi.total_sales DESC
LIMIT 100
