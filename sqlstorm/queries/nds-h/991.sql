WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
HighCostSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty > 0
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp)
),
OrderDetails AS (
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
)
SELECT 
    r.p_partkey, 
    r.p_name, 
    r.total_cost,
    COALESCE(s.total_supply_cost, 0) AS supplier_cost,
    d.total_revenue,
    CASE 
        WHEN r.rank = 1 THEN 'Top Part'
        ELSE 'Other Part'
    END AS part_category
FROM 
    RankedParts r
LEFT JOIN 
    HighCostSuppliers s ON r.p_brand = s.s_name
LEFT JOIN 
    OrderDetails d ON r.p_partkey = d.o_orderkey
WHERE 
    (d.total_revenue IS NULL OR d.total_revenue > 50000)
ORDER BY 
    r.total_cost DESC, s.total_supply_cost DESC;
