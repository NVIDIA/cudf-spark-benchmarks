
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND 
        o.o_orderdate < DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(RO.total_revenue) AS customer_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        RankedOrders RO ON o.o_orderkey = RO.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(RO.total_revenue) > 100000
)
SELECT 
    c.c_custkey,
    c.c_name,
    c.c_acctbal,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(RO.total_revenue) AS total_spent
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    RankedOrders RO ON o.o_orderkey = RO.o_orderkey
WHERE 
    c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA'))
GROUP BY 
    c.c_custkey, c.c_name, c.c_acctbal
ORDER BY 
    total_spent DESC
LIMIT 10;
