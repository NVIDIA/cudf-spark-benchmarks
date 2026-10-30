WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS part_rank
    FROM 
        part p
    WHERE 
        LENGTH(p.p_name) > 20
), FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 50000 AND 
        s.s_comment LIKE '%reliable%'
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 5
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.p_retailprice,
    fs.s_name,
    fs.nation_name,
    co.c_name,
    co.order_count,
    co.total_spent
FROM 
    RankedParts fp
JOIN 
    FilteredSuppliers fs ON fp.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 100 LIMIT 1)
JOIN 
    CustomerOrders co ON fs.s_suppkey = (SELECT l.l_suppkey FROM lineitem l WHERE l.l_quantity > 10 LIMIT 1)
WHERE 
    fp.part_rank <= 5
ORDER BY 
    fp.p_retailprice DESC, 
    co.total_spent DESC;
