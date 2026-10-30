WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        RANK() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) as rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
FinalAnalysis AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(ho.total_revenue) AS total_revenue,
        SUM(rv.total_value) AS total_supply_value
    FROM 
        HighValueOrders ho
    JOIN 
        customer c ON ho.o_orderkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        RankedSuppliers rv ON rv.s_suppkey = ho.o_orderkey
    GROUP BY 
        n.n_name
)
SELECT 
    nation_name,
    customer_count,
    total_revenue,
    total_supply_value
FROM 
    FinalAnalysis
ORDER BY 
    total_revenue DESC, customer_count DESC
LIMIT 10;
