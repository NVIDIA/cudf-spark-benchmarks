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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY LENGTH(p.p_comment) DESC) AS rn
    FROM part p
    WHERE p.p_size BETWEEN 10 AND 20
),
SupplierParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        p.p_partkey, 
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_retailprice,
        p.p_comment
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN RankedParts p ON ps.ps_partkey = p.p_partkey
    WHERE p.rn <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE li.l_returnflag = 'N'
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    cp.s_name AS SupplierName,
    cp.p_name AS PartName,
    co.c_name AS CustomerName,
    co.o_orderkey,
    co.total_sales
FROM SupplierParts cp
JOIN CustomerOrders co ON cp.ps_availqty > 0
ORDER BY co.total_sales DESC, cp.p_name, cp.s_name
LIMIT 100;
