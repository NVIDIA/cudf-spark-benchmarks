WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_comment LIKE '%reliable%'
), FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_type,
        p.p_retailprice,
        p.p_comment,
        CHAR_LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%widget%'
        AND p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
), OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS num_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.s_suppkey, 
    r.s_name, 
    r.s_address, 
    fp.p_partkey, 
    fp.p_name, 
    fp.p_retailprice, 
    od.total_revenue, 
    od.num_parts
FROM 
    RankedSuppliers r
JOIN 
    FilteredParts fp ON r.rn = 1
JOIN 
    OrderDetails od ON fp.p_partkey = od.o_orderkey
WHERE 
    r.s_name ILIKE '%Acme%' 
ORDER BY 
    od.total_revenue DESC, r.s_acctbal DESC;
