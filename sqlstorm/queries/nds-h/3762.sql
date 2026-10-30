WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND
        l.l_shipdate < cast('1998-10-01' as date) - INTERVAL '30' DAY
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS cust_total_revenue
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, r.r_name
),
TopCustomers AS (
    SELECT 
        cr.c_custkey,
        cr.r_name,
        cr.cust_total_revenue,
        ROW_NUMBER() OVER (PARTITION BY cr.r_name ORDER BY cr.cust_total_revenue DESC) AS customer_rank
    FROM 
        CustomerRegion cr
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.total_revenue,
    tc.r_name AS customer_region,
    tc.cust_total_revenue,
    CASE 
        WHEN o.total_revenue > 10000 THEN 'High'
        WHEN o.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS revenue_classification
FROM 
    RankedOrders o
LEFT JOIN 
    TopCustomers tc ON o.o_orderkey = tc.c_custkey
WHERE 
    o.order_rank <= 5 OR tc.customer_rank <= 5
ORDER BY 
    o.o_orderdate DESC, total_revenue DESC;