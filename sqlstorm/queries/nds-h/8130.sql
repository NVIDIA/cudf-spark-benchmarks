WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), CustomerRevenue AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(ro.total_revenue) AS customer_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        RankedOrders ro ON o.o_orderkey = ro.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
), TopCustomers AS (
    SELECT 
        cr.c_custkey,
        cr.c_name,
        cr.customer_revenue,
        RANK() OVER (ORDER BY cr.customer_revenue DESC) AS revenue_rank
    FROM 
        CustomerRevenue cr
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    tc.customer_revenue,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    ps.ps_supplycost,
    ps.ps_availqty
FROM 
    TopCustomers tc
JOIN 
    partsupp ps ON ps.ps_partkey IN (
        SELECT ps2.ps_partkey 
        FROM partsupp ps2 
        JOIN supplier s ON ps2.ps_suppkey = s.s_suppkey 
        WHERE s.s_nationkey IN (
            SELECT n.n_nationkey 
            FROM nation n 
            WHERE n.n_name = 'USA'
        )
    )
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    tc.revenue_rank <= 10
ORDER BY 
    tc.customer_revenue DESC, 
    p.p_name ASC;