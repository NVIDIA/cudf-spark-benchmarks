
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
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        s.total_supply_cost, 
        RANK() OVER (ORDER BY s.total_supply_cost DESC) AS supply_rank
    FROM 
        SupplierDetails s
    WHERE 
        s.total_supply_cost IS NOT NULL
)
SELECT 
    ro.o_orderkey, 
    ro.o_orderdate, 
    ro.total_revenue, 
    ts.s_suppkey, 
    ts.s_name, 
    ts.total_supply_cost
FROM 
    RankedOrders ro
JOIN 
    lineitem l ON ro.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
WHERE 
    ro.revenue_rank <= 10 
    AND ts.supply_rank IS NOT NULL
ORDER BY 
    ro.o_orderdate DESC, 
    ro.total_revenue DESC;
