
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    GROUP BY 
        s.s_suppkey, s.s_name
), 
OrderDetail AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)

SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    ts.s_name AS supplier_name,
    AVG(od.order_value) AS average_order_value,
    COUNT(DISTINCT od.o_orderkey) AS total_orders,
    CASE 
        WHEN COUNT(DISTINCT od.o_orderkey) > 0 
        THEN SUM(CASE WHEN od.order_value > 1000 THEN 1 ELSE 0 END)
        ELSE NULL 
    END AS high_value_order_count
FROM 
    RankedParts rp
LEFT JOIN 
    TopSuppliers ts ON rp.p_partkey = ts.s_suppkey 
LEFT JOIN 
    OrderDetail od ON od.o_orderkey = rp.p_partkey
WHERE 
    rp.rn = 1
GROUP BY 
    rp.p_partkey, rp.p_name, rp.p_brand, ts.s_name, rp.p_retailprice
HAVING 
    AVG(od.order_value) > (SELECT AVG(order_value) FROM OrderDetail)
ORDER BY 
    rp.p_retailprice DESC NULLS LAST;
