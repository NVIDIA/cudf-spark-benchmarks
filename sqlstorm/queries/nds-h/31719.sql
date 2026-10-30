WITH  RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT ps.ps_availqty FROM partsupp ps WHERE ps.ps_supplycost > 100)
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey
),
SupplierNation AS (
    SELECT 
        s.s_suppkey,
        n.n_name AS supplier_nation,
        COUNT(DISTINCT ps.ps_partkey) AS available_parts
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, n.n_name
)
SELECT 
    R.p_name,
    R.p_retailprice,
    O.total_revenue,
    S.supplier_nation,
    S.available_parts
FROM 
    RankedParts R
LEFT JOIN 
    OrderSummary O ON R.rn = 1
JOIN 
    SupplierNation S ON R.p_partkey = S.available_parts
WHERE 
    COALESCE(O.total_revenue, 0) > 1000
    AND S.available_parts IS NOT NULL
ORDER BY 
    R.p_retailprice DESC, 
    O.total_revenue DESC
LIMIT 10;