WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
HighAccountBalance AS (
    SELECT 
        r.r_name,
        n.n_name,
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 10000
    GROUP BY 
        r.r_name, n.n_name, c.c_custkey, c.c_name
),
SupplierRanking AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY rs.total_supply_cost DESC) AS rank
    FROM 
        RankedSuppliers rs
)
SELECT 
    h.r_name,
    h.n_name,
    h.c_custkey,
    h.c_name,
    sr.s_name AS top_supplier,
    sr.total_supply_cost
FROM 
    HighAccountBalance h
JOIN 
    SupplierRanking sr ON sr.rank = 1
WHERE 
    h.total_revenue > (SELECT AVG(total_revenue) FROM HighAccountBalance);
