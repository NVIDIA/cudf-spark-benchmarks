
WITH PurchaseStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
TopCustomers AS (
    SELECT 
        ps.c_customer_sk,
        ps.c_first_name,
        ps.c_last_name,
        ps.cd_gender,
        ps.total_orders,
        ps.total_spent
    FROM 
        PurchaseStats ps
    WHERE 
        ps.total_orders > 5 AND ps.gender_rank <= 10
),
ReturnedSales AS (
    SELECT 
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_quantity) AS total_returned_qty,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returned_date_sk, wr.wr_item_sk, wr.wr_returning_customer_sk
),
SalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold_qty,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_sales,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_price,
        COALESCE(SUM(rs.total_returned_qty), 0) AS total_returned_qty,
        COALESCE(SUM(rs.total_returned_amt), 0) AS total_returned_amt
    FROM 
        web_sales ws
    LEFT JOIN 
        ReturnedSales rs ON ws.ws_item_sk = rs.wr_item_sk
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    ss.total_sold_qty,
    ss.total_net_sales,
    ss.avg_net_price,
    CASE 
        WHEN ss.total_returned_qty > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM 
    TopCustomers tc
JOIN 
    SalesSummary ss ON tc.c_customer_sk = ss.ws_item_sk
ORDER BY 
    tc.total_spent DESC, ss.total_net_sales DESC;
