
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
MemberPartSuppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        COALESCE(NULLIF(p.p_name, ''), 'UNKNOWN') AS part_name,
        CASE 
            WHEN ps.ps_supplycost > 500 THEN 'HIGH'
            WHEN ps.ps_supplycost BETWEEN 200 AND 500 THEN 'MEDIUM'
            ELSE 'LOW' 
        END AS supply_category
    FROM 
        partsupp ps
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
)

SELECT 
    r.r_name AS region_name,
    s.s_name AS supplier_name,
    m.part_name,
    m.supply_category,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(m.ps_availqty) AS total_available_quantity,
    MAX(COALESCE(l.l_discount, 0)) AS max_discount_applied,
    (SELECT COUNT(*) FROM orders o2 WHERE o2.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31') AS orders_count_1995,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(m.ps_supplycost) DESC) AS row_num
FROM 
    RankedSuppliers s
JOIN 
    nation n ON s.s_suppkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    MemberPartSuppliers m ON s.s_suppkey = m.ps_suppkey
LEFT JOIN 
    CustomerOrderSummary c ON c.c_custkey = s.s_suppkey
LEFT JOIN 
    lineitem l ON m.ps_partkey = l.l_partkey
WHERE 
    s.rank_acctbal <= 10 
    AND (m.supply_category = 'HIGH' OR m.supply_category = 'MEDIUM') 
    AND (l.l_returnflag IS NULL OR l.l_returnflag <> 'R')
GROUP BY 
    r.r_name, s.s_name, m.part_name, m.supply_category, r.r_regionkey, s.s_suppkey, m.ps_supplycost
HAVING 
    COUNT(DISTINCT c.c_custkey) > 0
    AND SUM(m.ps_availqty) IS NOT NULL
ORDER BY 
    region_name, supplier_name;
