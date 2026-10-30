
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_mktsegment,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_mktsegment
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.total_revenue,
    h.s_name,
    h.total_supply_cost,
    CASE 
        WHEN h.total_supply_cost IS NULL THEN 'No Cost Data'
        ELSE 'Valid Cost Data'
    END AS cost_data_status
FROM 
    RankedOrders r
LEFT JOIN 
    HighValueSuppliers h ON r.revenue_rank = 1
WHERE 
    r.total_revenue > 10000
ORDER BY 
    r.o_orderdate DESC, r.total_revenue DESC;
