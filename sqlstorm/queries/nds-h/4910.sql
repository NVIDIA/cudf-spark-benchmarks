WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_custkey
),
CustomerRanking AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (ORDER BY AVG(r.total_revenue) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        RankedOrders r ON c.c_custkey = r.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
)
SELECT 
    cr.rank,
    cr.c_name,
    COALESCE(SUM(ps.ps_supplycost), 0) AS total_supply_cost,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
    MAX(SUBSTRING(p.p_name, 1, 10)) AS sample_part_name
FROM 
    CustomerRanking cr
LEFT JOIN 
    partsupp ps ON cr.c_custkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    cr.rank <= 10 AND 
    cr.c_acctbal IS NOT NULL AND 
    cr.c_name IS NOT NULL
GROUP BY 
    cr.rank, cr.c_name
ORDER BY 
    cr.rank;
