WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
TopSuppliers AS (
    SELECT 
        ps.ps_suppkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        ps.ps_suppkey
),
Regions AS (
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    ro.o_orderkey,
    ro.revenue,
    ts.total_spent,
    rg.r_name,
    rg.nation_count
FROM 
    RankedOrders ro
JOIN 
    TopSuppliers ts ON ro.o_orderkey = ts.ps_suppkey
JOIN 
    Regions rg ON ts.ps_suppkey = rg.r_regionkey
WHERE 
    ro.revenue_rank <= 10 AND ts.rank <= 10
ORDER BY 
    ro.revenue DESC, ts.total_spent DESC;