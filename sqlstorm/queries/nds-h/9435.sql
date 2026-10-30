
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderstatus
),
TopSuppliers AS (
    SELECT 
        ps.ps_suppkey, 
        SUM(l.l_quantity) AS total_supplied
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        SUM(l.l_quantity) > 1000
),
CustomerRegion AS (
    SELECT 
        c.c_custkey, 
        n.n_regionkey
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT co.c_custkey) AS customers_count,
    SUM(ro.total_revenue) AS total_revenue
FROM 
    RankedOrders ro
JOIN 
    CustomerRegion co ON ro.o_custkey = co.c_custkey
JOIN 
    region r ON co.n_regionkey = r.r_regionkey
JOIN 
    TopSuppliers ts ON ro.o_custkey = ts.ps_suppkey
WHERE 
    ro.order_rank <= 10
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC;
