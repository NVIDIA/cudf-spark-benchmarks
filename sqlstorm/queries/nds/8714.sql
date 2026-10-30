WITH filtered_customers AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 2458400 AND 2458460  
    GROUP BY
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
ranked_customers AS (
    SELECT
        c.*,
        RANK() OVER (PARTITION BY c.cd_gender ORDER BY c.total_net_profit DESC) AS profit_rank
    FROM
        filtered_customers c
)
SELECT
    rc.c_customer_id,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.total_net_profit,
    rc.order_count
FROM
    ranked_customers rc
WHERE
    rc.profit_rank <= 10  
ORDER BY
    rc.cd_gender, rc.total_net_profit DESC;