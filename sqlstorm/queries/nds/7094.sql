
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_paid
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
), TopCustomers AS (
    SELECT 
        c.*,
        RANK() OVER (ORDER BY total_net_profit DESC) AS rank_profit,
        RANK() OVER (ORDER BY total_quantity DESC) AS rank_quantity
    FROM 
        CustomerSummary c
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_quantity,
    tc.total_net_profit,
    tc.order_count,
    tc.total_paid
FROM 
    TopCustomers tc
WHERE 
    tc.rank_profit <= 10 OR tc.rank_quantity <= 10
ORDER BY 
    tc.rank_profit, tc.rank_quantity;
