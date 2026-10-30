
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS customer_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SelectedNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name = 'ASIA'
)
SELECT 
    nc.n_name,
    tc.c_name,
    rc.total_revenue,
    CAST(nc.n_nationkey AS STRING) AS nation_key
FROM 
    TopCustomers tc
JOIN 
    SelectedNations nc ON tc.c_custkey IN (SELECT s.s_nationkey FROM supplier s WHERE s.s_nationkey = nc.n_nationkey)
JOIN 
    RankedOrders rc ON tc.customer_revenue = rc.total_revenue
ORDER BY 
    rc.total_revenue DESC, nc.n_name;
