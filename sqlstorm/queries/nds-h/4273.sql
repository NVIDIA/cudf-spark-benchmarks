
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_linenumber) AS item_count,
        o.o_orderdate,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    rs.s_name AS supplier_name,
    os.total_price,
    os.item_count,
    CASE 
        WHEN os.total_price IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status,
    p.p_retailprice * COALESCE(NULLIF(rs.s_acctbal, 0), 1) AS adjusted_retail_price
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey AND rs.rank <= 5
LEFT JOIN 
    OrderSummary os ON p.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = os.o_orderkey)
WHERE 
    p.p_container LIKE 'SMALL%' 
    AND p.p_size BETWEEN 1 AND 20
ORDER BY 
    adjusted_retail_price DESC, supplier_name;
