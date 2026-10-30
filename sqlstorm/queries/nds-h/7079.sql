
WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(ps.ps_partkey) AS supplied_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
) 
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    p.p_type AS part_type,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    AVG(rp.total_available_qty) AS avg_available_qty,
    SUM(ss.total_supply_cost) AS total_supplier_cost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem li ON p.p_partkey = li.l_partkey
JOIN 
    orders o ON li.l_orderkey = o.o_orderkey
JOIN 
    RankedParts rp ON p.p_partkey = rp.p_partkey
JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    r.r_name, n.n_name, p.p_type, rp.total_available_qty, ss.total_supply_cost
HAVING 
    COUNT(o.o_orderkey) > 100
ORDER BY 
    total_revenue DESC, avg_available_qty ASC;
