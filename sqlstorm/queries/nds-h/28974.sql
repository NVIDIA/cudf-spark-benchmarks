WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_name LIKE '%S%'
), FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_comment
    FROM supplier s
    WHERE s.s_comment LIKE '%limited%'
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_type,
    fs.s_name AS supplier_name,
    fs.s_phone AS supplier_phone,
    co.c_name AS customer_name,
    co.o_orderdate,
    co.o_totalprice
FROM RankedParts rp
JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN FilteredSuppliers fs ON fs.s_suppkey = ps.ps_suppkey
JOIN CustomerOrders co ON co.o_orderkey = ps.ps_partkey
WHERE rp.rank <= 5
ORDER BY rp.p_brand, co.o_orderdate DESC;