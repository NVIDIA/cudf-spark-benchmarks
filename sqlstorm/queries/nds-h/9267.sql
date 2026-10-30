WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate <= DATE '1997-12-31'
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_supplycost,
        SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate <= DATE '1997-12-31'
    GROUP BY 
        ps.ps_partkey, ps.ps_supplycost
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(sc.total_revenue) AS total_revenue
    FROM 
        supplier s
    JOIN 
        SupplierCosts sc ON s.s_suppkey = sc.ps_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
    ORDER BY 
        total_revenue DESC
    LIMIT 10
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ts.s_name,
    ts.total_revenue
FROM 
    RankedOrders ro
JOIN 
    TopSuppliers ts ON ts.total_revenue > 100000
WHERE 
    ro.rank <= 5
ORDER BY 
    ro.o_orderdate DESC, ts.total_revenue DESC;