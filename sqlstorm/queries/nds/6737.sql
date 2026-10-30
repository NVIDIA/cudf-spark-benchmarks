
WITH customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent,
        AVG(ws.ws_sales_price) AS avg_order_value,
        COUNT(DISTINCT wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt) AS total_returned
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
ranked_customers AS (
    SELECT 
        cus.*,
        RANK() OVER (ORDER BY total_spent DESC) AS spend_rank,
        RANK() OVER (ORDER BY total_orders DESC) AS order_rank
    FROM 
        customer_summary cus
)
SELECT 
    rc.c_customer_id,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_education_status,
    rc.total_orders,
    rc.total_spent,
    rc.avg_order_value,
    rc.total_returns,
    rc.total_returned,
    rc.spend_rank,
    rc.order_rank
FROM 
    ranked_customers rc
WHERE 
    rc.spend_rank <= 10 OR rc.order_rank <= 10
ORDER BY 
    rc.spend_rank, rc.order_rank;
