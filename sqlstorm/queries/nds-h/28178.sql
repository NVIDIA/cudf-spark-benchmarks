WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment
    FROM 
        part p
    WHERE 
        p.p_size >= 10 
        AND p.p_type LIKE '%brass%'
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    fs.s_name AS supplier_name,
    fs.nation AS supplier_nation,
    fp.p_name AS part_name,
    os.total_revenue,
    os.item_count
FROM 
    RankedSuppliers fs
JOIN 
    partsupp ps ON fs.s_suppkey = ps.ps_suppkey
JOIN 
    FilteredParts fp ON ps.ps_partkey = fp.p_partkey
JOIN 
    OrderSummary os ON os.o_orderkey = ps.ps_partkey  
WHERE 
    fs.rank <= 5
ORDER BY 
    total_revenue DESC, 
    supplier_name ASC;