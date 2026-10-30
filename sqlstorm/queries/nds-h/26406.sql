WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_container, 
        p.p_retailprice, 
        p.p_comment,
        RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) as price_rank
    FROM 
        part p
), FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
), OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_partkey) AS unique_parts_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    rp.p_name, 
    fs.s_name, 
    od.total_order_value,
    od.unique_parts_count,
    fs.comment_length
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    FilteredSuppliers fs ON ps.ps_suppkey = fs.s_suppkey
JOIN 
    OrderDetails od ON fs.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA') 
WHERE 
    rp.price_rank <= 5 AND 
    fs.comment_length > 50
ORDER BY 
    od.total_order_value DESC, 
    rp.p_name;