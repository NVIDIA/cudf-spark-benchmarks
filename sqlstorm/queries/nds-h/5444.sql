
WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rnk
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 5 AND 15
),
SupplierAndParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name AS supp_name, 
        pp.p_partkey, 
        pp.p_name, 
        pp.p_retailprice,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        RankedParts pp ON ps.ps_partkey = pp.p_partkey
    WHERE 
        s.s_acctbal > 5000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS order_total
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        c.c_mktsegment = 'BUILDING' 
        AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey
    HAVING 
        SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
)
SELECT 
    r.supp_name, 
    r.p_name, 
    r.p_retailprice, 
    co.c_name, 
    co.order_total
FROM 
    SupplierAndParts r
JOIN 
    CustomerOrders co ON r.p_partkey = co.o_orderkey
ORDER BY 
    r.p_retailprice DESC, 
    co.order_total ASC
LIMIT 100;
