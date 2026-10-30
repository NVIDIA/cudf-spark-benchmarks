
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost * ps_availqty) FROM partsupp)
), 
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)

SELECT 
    p.p_name,
    p.p_brand,
    r.r_name AS region_name,
    COALESCE(hp.total_value, 0) AS total_high_value,
    o.total_order_value,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    MAX(s.s_acctbal) AS max_supplier_balance
FROM 
    part p
LEFT JOIN 
    HighValueParts hp ON p.p_partkey = hp.ps_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    OrderSummary o ON o.o_orderkey = ps.ps_partkey
WHERE 
    p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
    AND (s.s_acctbal IS NOT NULL OR s.s_acctbal < 1000)
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, r.r_name, hp.total_value, o.total_order_value
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 1
ORDER BY 
    o.total_order_value DESC, max_supplier_balance ASC;
