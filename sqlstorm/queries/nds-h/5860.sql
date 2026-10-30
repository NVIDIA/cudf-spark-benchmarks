WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        rs.nation_name
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 5
),
PartSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    ps.s_name AS supplier_name,
    ps.nation_name,
    pm.p_name AS part_name,
    SUM(li.l_quantity) AS total_quantity,
    SUM(li.l_extendedprice) AS total_revenue,
    AVG(li.l_discount) AS average_discount,
    AVG(li.l_tax) AS average_tax
FROM 
    lineitem li
JOIN 
    orders o ON li.l_orderkey = o.o_orderkey
JOIN 
    TopSuppliers ps ON li.l_suppkey = ps.s_suppkey
JOIN 
    PartSummary pm ON li.l_partkey = pm.p_partkey
WHERE 
    o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
GROUP BY 
    ps.s_name, ps.nation_name, pm.p_name
ORDER BY 
    total_revenue DESC
LIMIT 10;