WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice BETWEEN 100 AND 500
),
CustomerNation AS (
    SELECT 
        c.c_custkey,
        n.n_name,
        COUNT(o.o_orderkey) AS order_count,
        AVG(c.c_acctbal) AS avg_acctbal
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, n.n_name
),
SupplierRanking AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supplycost,
        COUNT(ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 2
)
SELECT 
    pn.p_partkey,
    pn.p_name,
    CN.avg_acctbal,
    SR.total_supplycost,
    CASE 
        WHEN cn.order_count > 10 THEN 'Frequent Buyer' 
        ELSE 'Occasional Buyer' 
    END AS buyer_type,
    COALESCE(sr.part_count, 0) AS supplier_parts,
    CONCAT('Supplier: ', COALESCE(sr.s_name, 'Unknown')) AS supplier_info
FROM 
    RankedParts pn
LEFT JOIN 
    CustomerNation CN ON pn.p_partkey = CN.c_custkey
FULL OUTER JOIN 
    SupplierRanking SR ON CN.order_count = SR.part_count
WHERE 
    (pn.rn = 1 OR CN.avg_acctbal IS NOT NULL) 
    AND COALESCE(SR.total_supplycost, 0) > 100
ORDER BY 
    pn.p_retailprice DESC, CN.avg_acctbal ASC;
