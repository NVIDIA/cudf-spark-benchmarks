WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank,
        n.n_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT ps.ps_suppkey) AS supply_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        MAX(o.o_orderdate) AS latest_order_date,
        COUNT(DISTINCT l.l_orderkey) AS total_lines
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' AND
        l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    pd.p_name,
    pd.p_retailprice,
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
    pd.total_available,
    pd.supply_count,
    os.total_price,
    os.latest_order_date,
    os.total_lines,
    CASE 
        WHEN pd.total_available IS NULL THEN 'Unknown'
        WHEN pd.total_available > 100 THEN 'Ample Supply'
        ELSE 'Limited Supply'
    END AS supply_status
FROM 
    PartDetails pd
LEFT JOIN 
    RankedSuppliers rs ON pd.supply_count = rs.supplier_rank
LEFT JOIN 
    OrderSummary os ON pd.p_partkey = os.o_orderkey
WHERE 
    pd.p_retailprice < (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size > 0)
AND 
    (pd.total_available IS NOT NULL OR rs.s_suppkey IS NULL)
ORDER BY 
    supply_status, pd.p_retailprice DESC;