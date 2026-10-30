
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 0
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
        AND l.l_returnflag IS NULL
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierPartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        COALESCE(SUM(l.l_quantity), 0) AS total_quantity
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, ps.ps_supplycost
)
SELECT 
    rp.s_name,
    rp.rank,
    sp.p_name,
    sp.total_quantity,
    sp.ps_supplycost,
    hv.total_value,
    CASE 
        WHEN hv.total_value IS NOT NULL THEN 'Value Reached'
        ELSE 'No Value'
    END AS value_status,
    CASE 
        WHEN rp.rank = 1 THEN 'Top Supplier'
        ELSE 'Other Supplier'
    END AS supplier_status
FROM 
    RankedSuppliers rp
JOIN 
    SupplierPartInfo sp ON rp.s_suppkey = sp.ps_supplycost
LEFT JOIN 
    HighValueOrders hv ON sp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = rp.s_suppkey)
WHERE 
    sp.total_quantity > 0
ORDER BY 
    rp.rank ASC, sp.total_quantity DESC
LIMIT 10;
