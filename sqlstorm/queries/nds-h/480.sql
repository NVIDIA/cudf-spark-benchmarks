WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
SupplierSummary AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        COUNT(l.l_linenumber) AS line_count,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        COUNT(l.l_linenumber) > 3
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    COALESCE(ss.total_parts, 0) AS total_parts_by_supplier,
    COALESCE(ss.total_supply_cost, 0) AS total_supply_cost_by_supplier,
    od.order_value,
    od.line_count,
    od.o_orderdate
FROM 
    RankedParts rp
LEFT JOIN 
    SupplierSummary ss ON rp.p_partkey = ss.total_parts
LEFT JOIN 
    OrderDetails od ON rp.p_partkey = od.o_orderkey
WHERE 
    rp.rn = 1
ORDER BY 
    rp.p_brand, rp.p_retailprice DESC, od.order_value DESC
LIMIT 100;
