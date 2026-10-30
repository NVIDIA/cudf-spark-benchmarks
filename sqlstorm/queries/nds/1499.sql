
WITH CustomerReturnStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        AVG(CASE WHEN sr_return_quantity > 0 THEN sr_return_quantity ELSE NULL END) AS avg_return_quantity
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        crs.c_customer_sk,
        crs.return_count,
        crs.total_return_amt,
        RANK() OVER (ORDER BY crs.total_return_amt DESC) AS rank
    FROM 
        CustomerReturnStats crs
    WHERE 
        crs.return_count > 5
),
WebSalesStats AS (
    SELECT 
        ws.ws_bill_customer_sk,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_coupon_amt) AS total_coupons_used
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    cu.c_customer_id,
    COALESCE(ts.return_count, 0) AS return_count,
    COALESCE(ts.total_return_amt, 0) AS total_return_amt,
    COALESCE(ws.order_count, 0) AS order_count,
    COALESCE(ws.total_sales, 0) AS total_sales,
    COALESCE(ws.total_coupons_used, 0) AS total_coupons_used,
    CASE 
        WHEN COALESCE(ts.return_count, 0) > 0 THEN 'Returns Available'
        ELSE 'No Returns'
    END AS return_status
FROM 
    customer cu
LEFT JOIN 
    TopCustomers ts ON cu.c_customer_sk = ts.c_customer_sk
LEFT JOIN 
    WebSalesStats ws ON cu.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    cu.c_birth_year BETWEEN 1980 AND 1990
    AND cu.c_preferred_cust_flag = 'Y'
ORDER BY 
    return_count DESC, total_sales DESC;
