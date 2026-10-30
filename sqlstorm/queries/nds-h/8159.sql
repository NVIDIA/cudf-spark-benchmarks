WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1994-01-01' AND DATE '1994-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT p.ps_partkey) AS parts_supplied,
        SUM(p.ps_supplycost * p.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp p ON s.s_suppkey = p.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), NationRevenue AS (
    SELECT 
        n.n_name,
        SUM(ro.total_revenue) AS total_nation_revenue
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.o_orderkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    r.r_name,
    nr.total_nation_revenue,
    sp.parts_supplied,
    sp.total_supply_cost
FROM 
    region r
LEFT JOIN 
    nationRevenue nr ON r.r_name = nr.n_name
LEFT JOIN 
    SupplierPerformance sp ON sp.parts_supplied > 10
ORDER BY 
    nr.total_nation_revenue DESC, sp.total_supply_cost ASC
LIMIT 10;
