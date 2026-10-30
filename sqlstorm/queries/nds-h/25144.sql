WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        s.s_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 50000 AND 
        s.s_comment LIKE '%reliable%'
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F' AND 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
)
SELECT 
    fp.p_partkey, 
    fp.p_name, 
    fs.s_name AS supplier_name, 
    co.c_name AS customer_name, 
    co.o_orderkey, 
    co.o_orderdate
FROM 
    RankedParts fp
JOIN 
    partsupp ps ON fp.p_partkey = ps.ps_partkey
JOIN 
    FilteredSuppliers fs ON ps.ps_suppkey = fs.s_suppkey
JOIN 
    lineitem li ON ps.ps_partkey = li.l_partkey
JOIN 
    CustomerOrders co ON li.l_orderkey = co.o_orderkey
WHERE 
    fp.brand_rank <= 3
ORDER BY 
    fp.p_brand, 
    co.o_orderdate DESC;