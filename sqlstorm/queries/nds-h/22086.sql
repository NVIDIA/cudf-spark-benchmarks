WITH RankedSuppliers AS (
    SELECT 
        s_suppkey, 
        s_name, 
        s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n_regionkey ORDER BY s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
AggregatedParts AS (
    SELECT 
        p.p_partkey, 
        SUM(ps.ps_supplycost) AS total_supplycost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p 
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey 
    GROUP BY 
        p.p_partkey
), 
OrderStatistics AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS lineitem_count,
        AVG(l.l_extendedprice) AS avg_price
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_returnflag IS NULL
    GROUP BY 
        o.o_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    rp.s_name AS top_supplier,
    ap.total_supplycost,
    os.lineitem_count,
    os.avg_price,
    COALESCE(rp.s_acctbal, 0) AS supplier_acctbal,
    (CASE 
        WHEN ap.supplier_count > 5 THEN 'High Supply'
        WHEN ap.supplier_count BETWEEN 3 AND 5 THEN 'Medium Supply'
        ELSE 'Low Supply'
    END) AS supply_category
FROM 
    part p
JOIN 
    AggregatedParts ap ON p.p_partkey = ap.p_partkey
LEFT JOIN 
    RankedSuppliers rp ON rp.rn = 1
LEFT JOIN 
    OrderStatistics os ON os.o_orderkey = (SELECT MIN(o.o_orderkey) 
                                               FROM orders o 
                                               WHERE o.o_orderdate < '1997-10-01' 
                                               AND o.o_orderstatus = 'O')
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) 
                          FROM part p2 
                          WHERE p2.p_size NOT IN (SELECT p3.p_size 
                                                    FROM part p3 
                                                    WHERE p3.p_retailprice IS NULL))
    AND p.p_mfgr NOT LIKE '%Acme%'
ORDER BY 
    ap.total_supplycost DESC,
    p.p_name ASC
LIMIT 10;